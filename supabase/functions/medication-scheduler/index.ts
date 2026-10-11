import { createClient } from "supabase";

// In-memory cache for Google OAuth2 access token to minimize RSA signing overhead
let cachedAccessToken: { token: string; expiresAt: number } | null = null;

/**
 * Converts a PEM-formatted PKCS#8 RSA private key to binary DER Uint8Array.
 */
function pemToDer(pem: string): Uint8Array {
  const clean = pem
    .replace(/-----BEGIN[ A-Z0-9_-]+-----/g, "")
    .replace(/-----END[ A-Z0-9_-]+-----/g, "")
    .replace(/[\r\n\s]/g, "");
  const binary = atob(clean);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

/**
 * Encodes a string or Uint8Array into URL-safe base64 (without padding).
 */
function base64UrlEncode(data: Uint8Array | string): string {
  if (typeof data === "string") {
    data = new TextEncoder().encode(data);
  }
  let binary = "";
  for (let i = 0; i < data.length; i++) {
    binary += String.fromCharCode(data[i]);
  }
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

/**
 * Obtains a Google OAuth2 access token using the service account private key via RS256 JWT assertion.
 */
async function getGoogleOAuth2AccessToken(serviceAccount: {
  client_email: string;
  private_key: string;
}): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  // Return cached token if valid for at least 5 more minutes
  if (cachedAccessToken && cachedAccessToken.expiresAt > now + 300) {
    return cachedAccessToken.token;
  }

  const normalizedPem = serviceAccount.private_key
    .replace(/\\n/g, "\n")
    .trim();

  const der = pemToDer(normalizedPem);

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

  const unsignedToken = `${base64UrlEncode(JSON.stringify(header))}.${base64UrlEncode(JSON.stringify(claims))}`;
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsignedToken)
  );

  const signedJwt = `${unsignedToken}.${base64UrlEncode(new Uint8Array(signature))}`;

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${signedJwt}`,
  });

  if (!tokenResponse.ok) {
    const errorBody = await tokenResponse.text();
    throw new Error(`Google OAuth2 token exchange failed: ${tokenResponse.status} - ${errorBody}`);
  }

  const tokenData = await tokenResponse.json();
  const accessToken = tokenData.access_token as string;
  const expiresIn = (tokenData.expires_in as number) || 3600;

  cachedAccessToken = {
    token: accessToken,
    expiresAt: now + expiresIn,
  };

  return accessToken;
}

/**
 * Sends a push notification via Firebase Cloud Messaging (FCM) HTTP v1 API.
 * Guarantees privacy: sensitive medical details are never sent in the lock-screen text.
 */
async function sendFcmV1Message({
  projectId,
  accessToken,
  fcmToken,
  title,
  body,
  data = {},
}: {
  projectId: string;
  accessToken: string;
  fcmToken: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}): Promise<{ success: boolean; messageId?: string; isInvalidToken?: boolean; error?: string }> {
  const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  // Stringify all data values for FCM HTTP v1 spec compliance
  const stringData: Record<string, string> = {};
  for (const [k, v] of Object.entries(data)) {
    stringData[k] = typeof v === "string" ? v : JSON.stringify(v);
  }

  const payload = {
    message: {
      token: fcmToken,
      notification: {
        title,
        body,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        ...stringData,
      },
      android: {
        priority: "high",
        notification: {
          channel_id: "careflow_high_importance_channel",
          sound: "default",
          default_sound: true,
          default_vibrate_timings: true,
        },
      },
    },
  };

  const response = await fetch(fcmEndpoint, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (response.ok) {
    const resJson = await response.json();
    const rawName = resJson.name || "";
    const messageId = rawName.split("/").pop() || "delivered";
    return { success: true, messageId };
  } else {
    const errJson = await response.json().catch(() => ({}));
    const errDetails = errJson?.error?.details?.[0];
    const errorCode = errDetails?.errorCode || errJson?.error?.status || `${response.status}`;
    const errorMessage = errJson?.error?.message || response.statusText;

    // Detect invalid, unregistered or expired device tokens
    const isInvalidToken =
      errorCode === "UNREGISTERED" ||
      errorCode === "INVALID_ARGUMENT" ||
      errorMessage.toLowerCase().includes("not a valid fcm registration token") ||
      errorMessage.toLowerCase().includes("registration token is not registered");

    return {
      success: false,
      isInvalidToken,
      error: `FCM Error [${errorCode}]: ${errorMessage}`,
    };
  }
}

/**
 * Main HTTP Handler for CareFlow Push Notifications & Medication Scheduler
 */
Deno.serve(async (req: Request) => {
  const correlationId = crypto.randomUUID();
  const startTime = Date.now();

  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Content-Type": "application/json",
  };

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const cronSecret = Deno.env.get("CRON_SECRET");
    const rawServiceAccount = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_KEY") ?? "";

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({
          error: "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY environment variables",
          correlation_id: correlationId,
        }),
        { status: 500, headers: corsHeaders }
      );
    }

    // Parse Firebase Service Account
    let serviceAccount: { project_id: string; client_email: string; private_key: string } | null = null;
    if (rawServiceAccount) {
      try {
        const trimmed = rawServiceAccount.trim();
        if (trimmed.startsWith("{")) {
          serviceAccount = JSON.parse(trimmed);
        } else {
          serviceAccount = JSON.parse(atob(trimmed));
        }
      } catch (err: any) {
        console.error(`[${correlationId}] Failed to parse FIREBASE_SERVICE_ACCOUNT_KEY:`, err.message);
      }
    }

    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace(/^Bearer\s+/i, "").trim();

    // Check if caller is authorized as admin/scheduler
    const isSystemAuthorized =
      token === supabaseServiceKey ||
      (cronSecret && token === cronSecret) ||
      req.headers.get("apikey") === supabaseServiceKey;

    let reqBody: Record<string, any> = {};
    if (req.method === "POST") {
      try {
        reqBody = await req.json();
      } catch (_) {
        reqBody = {};
      }
    }

    const action = reqBody.action || "scheduler_run";

    // -------------------------------------------------------------------------
    // ACTION 1: SEND TEST PUSH NOTIFICATION (Authenticated client user)
    // -------------------------------------------------------------------------
    if (action === "send_test") {
      // Validate authenticated caller JWT cryptographically via Supabase Auth
      const userClient = createClient(supabaseUrl, token ? token : supabaseServiceKey);
      let callerUser: { id: string; email?: string } | null = null;

      if (token && token !== supabaseServiceKey) {
        const { data: { user }, error: authErr } = await userClient.auth.getUser(token);
        if (authErr || !user) {
          return new Response(
            JSON.stringify({ error: "Unauthorized: Invalid user session token for send_test", correlation_id: correlationId }),
            { status: 401, headers: corsHeaders }
          );
        }
        callerUser = user;
      } else if (isSystemAuthorized) {
        // Fallback for admin test execution with provided recipient_id
        if (reqBody.user_id) {
          callerUser = { id: reqBody.user_id };
        }
      }

      if (!callerUser) {
        return new Response(
          JSON.stringify({ error: "Authentication required to send test notification", correlation_id: correlationId }),
          { status: 401, headers: corsHeaders }
        );
      }

      if (!serviceAccount || !serviceAccount.private_key) {
        return new Response(
          JSON.stringify({
            error: "FCM provider key (FIREBASE_SERVICE_ACCOUNT_KEY) is not configured in Supabase secrets",
            correlation_id: correlationId,
          }),
          { status: 503, headers: corsHeaders }
        );
      }

      // Query active device tokens for the authenticated caller
      const adminClient = createClient(supabaseUrl, supabaseServiceKey);
      const { data: tokens, error: tokenErr } = await adminClient
        .from("careflow_device_tokens")
        .select("id, fcm_token, platform")
        .eq("user_id", callerUser.id)
        .eq("is_active", true)
        .order("last_seen_at", { ascending: false });

      if (tokenErr || !tokens || tokens.length === 0) {
        return new Response(
          JSON.stringify({
            success: false,
            error: "No active device token found for your account. Please log in from the CareFlow Android app to register your device.",
            correlation_id: correlationId,
          }),
          { status: 200, headers: corsHeaders }
        );
      }

      const activeToken = tokens[0].fcm_token;
      const maskedToken = `${activeToken.substring(0, 8)}...${activeToken.substring(activeToken.length - 6)}`;

      // Obtain Google OAuth2 access token
      const googleToken = await getGoogleOAuth2AccessToken(serviceAccount);

      // Dispatch FCM HTTP v1 test message
      const title = reqBody.title || "CareFlow Test Notification";
      const body = reqBody.body || "Real-time push delivery verified on your Android device.";

      const fcmResult = await sendFcmV1Message({
        projectId: serviceAccount.project_id,
        accessToken: googleToken,
        fcmToken: activeToken,
        title,
        body,
        data: {
          type: "test_notification",
          timestamp: new Date().toISOString(),
          correlation_id: correlationId,
        },
      });

      if (fcmResult.success) {
        return new Response(
          JSON.stringify({
            success: true,
            message: "Test push notification delivered to FCM provider",
            fcm_message_id: fcmResult.messageId,
            masked_token: maskedToken,
            platform: tokens[0].platform,
            correlation_id: correlationId,
          }),
          { status: 200, headers: corsHeaders }
        );
      } else {
        if (fcmResult.isInvalidToken) {
          // Deactivate invalid token in database
          await adminClient
            .from("careflow_device_tokens")
            .update({ is_active: false })
            .eq("fcm_token", activeToken);
        }

        return new Response(
          JSON.stringify({
            success: false,
            error: fcmResult.error,
            is_invalid_token: fcmResult.isInvalidToken,
            correlation_id: correlationId,
          }),
          { status: 200, headers: corsHeaders }
        );
      }
    }

    // -------------------------------------------------------------------------
    // SYSTEM ACTIONS: REQUIRE SERVICE ROLE OR CRON_SECRET
    // -------------------------------------------------------------------------
    if (!isSystemAuthorized) {
      return new Response(
        JSON.stringify({
          error: "Unauthorized: Notification scheduler can only be invoked by authorized scheduler or service role.",
          correlation_id: correlationId,
        }),
        { status: 401, headers: corsHeaders }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // -------------------------------------------------------------------------
    // ACTION 2: DISPATCH SINGLE GENERAL NOTIFICATION (Called by DB Trigger / Webhook)
    // -------------------------------------------------------------------------
    if (action === "dispatch_notification" && reqBody.notification_id) {
      const { data: notif, error: notifErr } = await supabase
        .from("careflow_notifications")
        .select("*")
        .eq("id", reqBody.notification_id)
        .single();

      if (notifErr || !notif) {
        return new Response(
          JSON.stringify({ error: "Notification record not found", correlation_id: correlationId }),
          { status: 404, headers: corsHeaders }
        );
      }

      if (!serviceAccount) {
        return new Response(
          JSON.stringify({ error: "FCM service account not configured", correlation_id: correlationId }),
          { status: 503, headers: corsHeaders }
        );
      }

      // Query active tokens for recipient
      const { data: recipientTokens } = await supabase
        .from("careflow_device_tokens")
        .select("fcm_token")
        .eq("user_id", notif.user_id)
        .eq("is_active", true);

      if (!recipientTokens || recipientTokens.length === 0) {
        await supabase
          .from("careflow_notifications")
          .update({ fcm_status: "no_tokens", dispatched_at: new Date().toISOString() })
          .eq("id", notif.id);

        return new Response(
          JSON.stringify({ success: true, status: "no_tokens", correlation_id: correlationId }),
          { status: 200, headers: corsHeaders }
        );
      }

      const googleToken = await getGoogleOAuth2AccessToken(serviceAccount);
      let lastMessageId = "";
      let deliveryFailed = false;

      for (const tok of recipientTokens) {
        const result = await sendFcmV1Message({
          projectId: serviceAccount.project_id,
          accessToken: googleToken,
          fcmToken: tok.fcm_token,
          title: notif.title,
          body: notif.body || notif.message || "",
          data: {
            type: notif.type || "general",
            reference_id: notif.reference_id || "",
            dose_id: notif.dose_id || "",
            action_type: notif.action_type || "",
          },
        });

        if (result.success) {
          lastMessageId = result.messageId || "delivered";
        } else {
          deliveryFailed = true;
          if (result.isInvalidToken) {
            await supabase
              .from("careflow_device_tokens")
              .update({ is_active: false })
              .eq("fcm_token", tok.fcm_token);
          }
        }
      }

      await supabase
        .from("careflow_notifications")
        .update({
          fcm_status: lastMessageId ? "delivered" : "failed",
          fcm_message_id: lastMessageId || null,
          dispatched_at: new Date().toISOString(),
        })
        .eq("id", notif.id);

      return new Response(
        JSON.stringify({
          success: !deliveryFailed,
          fcm_message_id: lastMessageId,
          correlation_id: correlationId,
        }),
        { status: 200, headers: corsHeaders }
      );
    }

    // -------------------------------------------------------------------------
    // ACTION 3: RECURRING SCHEDULER RUN (Medication Doses + Outbox Processing)
    // -------------------------------------------------------------------------

    // 1. Atomically Claim & Transition Due Doses via Postgres RPC
    const { data: claimResult, error: claimError } = await supabase.rpc(
      "careflow_claim_and_process_due_doses",
      { p_limit: 50 }
    );

    if (claimError) {
      console.error(`[${correlationId}] Error claiming due doses:`, claimError.message);
    }

    // 2. Scan Appointment Reminders (24h prior / Day-of)
    try {
      await supabase.rpc("careflow_scan_appointment_reminders");
    } catch (_) {
      // Non-fatal if procedure is not yet applied
    }

    // 3. Atomically Claim Pending Alert Events (FOR UPDATE SKIP LOCKED)
    let pendingEvents: any[] = [];
    const { data: claimedEvents, error: claimEventsErr } = await supabase.rpc(
      "careflow_claim_pending_alert_events",
      { p_limit: 50 }
    );

    if (claimEventsErr) {
      const { data: fallbackEvents } = await supabase
        .from("careflow_medication_alert_events")
        .select("*")
        .in("status", ["created", "attempted"])
        .lt("retry_count", 5)
        .limit(50);
      pendingEvents = fallbackEvents || [];
    } else {
      pendingEvents = claimedEvents || [];
    }

    // 4. Atomically Claim Pending General Notifications (FOR UPDATE SKIP LOCKED)
    let pendingNotifications: any[] = [];
    try {
      const { data: claimedNotifs, error: claimNotifsErr } = await supabase.rpc(
        "careflow_claim_pending_notifications",
        { p_limit: 50 }
      );
      if (!claimNotifsErr && claimedNotifs) {
        pendingNotifications = claimedNotifs;
      }
    } catch (_) {
      // Fallback
    }

    let googleToken = "";
    if (serviceAccount) {
      try {
        googleToken = await getGoogleOAuth2AccessToken(serviceAccount);
      } catch (tokenErr: any) {
        console.error(`[${correlationId}] OAuth2 token error:`, tokenErr.message);
      }
    }

    const dispatchResults: Array<{ id: string; status: string; channel: string; messageId?: string }> = [];

    // Process Medication Alert Events Outbox
    if (pendingEvents && pendingEvents.length > 0) {
      for (const ev of pendingEvents) {
        try {
          // A. IN-APP CHANNEL: Row already saved, mark delivered
          if (ev.delivery_channel === "in_app") {
            await supabase
              .from("careflow_medication_alert_events")
              .update({
                status: "delivered",
                dispatched_at: new Date().toISOString(),
                updated_at: new Date().toISOString(),
              })
              .eq("id", ev.id);

            dispatchResults.push({ id: ev.id, status: "delivered", channel: "in_app" });
            continue;
          }

          // B. CONSENT RE-CHECK: If caregiver escalation, verify consent is active immediately before dispatch
          if (ev.event_type === "caregiver_escalation") {
            if (ev.recipient_type === "family") {
              const { data: consent } = await supabase
                .from("careflow_medication_alert_consents")
                .select("consent_status, medication_alert_permission")
                .eq("family_user_id", ev.recipient_id)
                .maybeSingle();

              if (!consent || consent.consent_status !== "granted" || !consent.medication_alert_permission) {
                await supabase
                  .from("careflow_medication_alert_events")
                  .update({
                    status: "failed",
                    failure_reason: "Caregiver alert consent has been revoked by patient",
                    updated_at: new Date().toISOString(),
                  })
                  .eq("id", ev.id);

                dispatchResults.push({ id: ev.id, status: "failed_revoked", channel: ev.delivery_channel });
                continue;
              }
            } else if (ev.recipient_type === "emergency_contact") {
              const { data: consent } = await supabase
                .from("careflow_medication_alert_consents")
                .select("consent_status, medication_alert_permission")
                .eq("emergency_contact_id", ev.recipient_id)
                .maybeSingle();

              if (!consent || consent.consent_status !== "granted" || !consent.medication_alert_permission) {
                await supabase
                  .from("careflow_medication_alert_events")
                  .update({
                    status: "failed",
                    failure_reason: "Emergency contact medication alert consent is inactive",
                    updated_at: new Date().toISOString(),
                  })
                  .eq("id", ev.id);

                dispatchResults.push({ id: ev.id, status: "failed_revoked", channel: ev.delivery_channel });
                continue;
              }
            }
          }

          // C. FCM PUSH NOTIFICATION CHANNEL
          if (ev.delivery_channel === "fcm") {
            if (!serviceAccount || !googleToken) {
              await supabase
                .from("careflow_medication_alert_events")
                .update({
                  status: "pending_provider_config",
                  failure_reason: "FIREBASE_SERVICE_ACCOUNT_KEY secret not configured in Supabase Edge Functions",
                  updated_at: new Date().toISOString(),
                })
                .eq("id", ev.id);

              dispatchResults.push({ id: ev.id, status: "pending_provider_config", channel: "fcm" });
              continue;
            }

            const { data: tokens } = await supabase
              .from("careflow_device_tokens")
              .select("fcm_token")
              .eq("user_id", ev.recipient_id)
              .eq("is_active", true);

            if (!tokens || tokens.length === 0) {
              await supabase
                .from("careflow_medication_alert_events")
                .update({
                  status: "failed",
                  failure_reason: "No active device tokens found for recipient",
                  updated_at: new Date().toISOString(),
                })
                .eq("id", ev.id);

              dispatchResults.push({ id: ev.id, status: "failed_no_tokens", channel: "fcm" });
              continue;
            }

            const payloadData = ev.payload || {};
            // Strict privacy: generic lock-screen text
            const title = payloadData.title || "CareFlow Dose Reminder";
            const body = payloadData.body || "Your scheduled dose is due. Tap to confirm.";

            let sentMessageId = "";
            let sendError = "";

            for (const tok of tokens) {
              const result = await sendFcmV1Message({
                projectId: serviceAccount.project_id,
                accessToken: googleToken,
                fcmToken: tok.fcm_token,
                title,
                body,
                data: {
                  type: ev.event_type,
                  dose_id: ev.dose_id || "",
                  recipient_id: ev.recipient_id,
                },
              });

              if (result.success) {
                sentMessageId = result.messageId || "delivered";
              } else {
                sendError = result.error || "FCM delivery failed";
                if (result.isInvalidToken) {
                  await supabase
                    .from("careflow_device_tokens")
                    .update({ is_active: false })
                    .eq("fcm_token", tok.fcm_token);
                }
              }
            }

            if (sentMessageId) {
              await supabase
                .from("careflow_medication_alert_events")
                .update({
                  status: "delivered",
                  fcm_message_id: sentMessageId,
                  dispatched_at: new Date().toISOString(),
                  updated_at: new Date().toISOString(),
                })
                .eq("id", ev.id);

              dispatchResults.push({ id: ev.id, status: "delivered", channel: "fcm", messageId: sentMessageId });
            } else {
              // Exponential backoff: 2 ^ (retry_count + 1) minutes
              const nextRetryMinutes = Math.pow(2, ev.retry_count + 1);
              const nextRetryDate = new Date(Date.now() + nextRetryMinutes * 60 * 1000).toISOString();

              await supabase
                .from("careflow_medication_alert_events")
                .update({
                  status: "attempted",
                  retry_count: ev.retry_count + 1,
                  next_retry_at: nextRetryDate,
                  failure_reason: sendError.substring(0, 200),
                  updated_at: new Date().toISOString(),
                })
                .eq("id", ev.id);

              dispatchResults.push({ id: ev.id, status: "attempted_retry_scheduled", channel: "fcm" });
            }
          }
        } catch (dispatchErr: any) {
          const nextRetryMinutes = Math.pow(2, (ev.retry_count || 0) + 1);
          const nextRetryDate = new Date(Date.now() + nextRetryMinutes * 60 * 1000).toISOString();

          await supabase
            .from("careflow_medication_alert_events")
            .update({
              status: "attempted",
              retry_count: (ev.retry_count || 0) + 1,
              next_retry_at: nextRetryDate,
              failure_reason: String(dispatchErr.message || dispatchErr).substring(0, 200),
              updated_at: new Date().toISOString(),
            })
            .eq("id", ev.id);

          dispatchResults.push({ id: ev.id, status: "attempted_retry_scheduled", channel: ev.delivery_channel });
        }
      }
    }

    // Process General Notifications Outbox (Appointments, Queue Calls, Prescriptions, Reports)
    if (pendingNotifications && pendingNotifications.length > 0) {
      for (const notif of pendingNotifications) {
        try {
          if (!serviceAccount || !googleToken) {
            await supabase
              .from("careflow_notifications")
              .update({ fcm_status: "failed", next_retry_at: new Date(Date.now() + 5 * 60 * 1000).toISOString() })
              .eq("id", notif.id);
            continue;
          }

          const { data: tokens } = await supabase
            .from("careflow_device_tokens")
            .select("fcm_token")
            .eq("user_id", notif.user_id)
            .eq("is_active", true);

          if (!tokens || tokens.length === 0) {
            await supabase
              .from("careflow_notifications")
              .update({ fcm_status: "no_tokens", dispatched_at: new Date().toISOString() })
              .eq("id", notif.id);

            dispatchResults.push({ id: notif.id, status: "no_tokens", channel: "general_notification" });
            continue;
          }

          let lastMessageId = "";
          let deliveryFailed = false;

          for (const tok of tokens) {
            const result = await sendFcmV1Message({
              projectId: serviceAccount.project_id,
              accessToken: googleToken,
              fcmToken: tok.fcm_token,
              title: notif.title || "CareFlow Notification",
              body: notif.body || notif.message || "You have a new update in CareFlow.",
              data: {
                type: notif.type || "general",
                reference_id: notif.reference_id || "",
                dose_id: notif.dose_id || "",
                action_type: notif.action_type || "",
              },
            });

            if (result.success) {
              lastMessageId = result.messageId || "delivered";
            } else {
              deliveryFailed = true;
              if (result.isInvalidToken) {
                await supabase
                  .from("careflow_device_tokens")
                  .update({ is_active: false })
                  .eq("fcm_token", tok.fcm_token);
              }
            }
          }

          if (lastMessageId) {
            await supabase
              .from("careflow_notifications")
              .update({
                fcm_status: "delivered",
                fcm_message_id: lastMessageId,
                dispatched_at: new Date().toISOString(),
              })
              .eq("id", notif.id);

            dispatchResults.push({ id: notif.id, status: "delivered", channel: "general_notification", messageId: lastMessageId });
          } else {
            const nextRetryMinutes = Math.pow(2, (notif.retry_count || 1));
            const nextRetryDate = new Date(Date.now() + nextRetryMinutes * 60 * 1000).toISOString();

            await supabase
              .from("careflow_notifications")
              .update({
                fcm_status: "failed",
                next_retry_at: nextRetryDate,
              })
              .eq("id", notif.id);

            dispatchResults.push({ id: notif.id, status: "failed_retry_scheduled", channel: "general_notification" });
          }
        } catch (err: any) {
          const nextRetryMinutes = Math.pow(2, (notif.retry_count || 1));
          const nextRetryDate = new Date(Date.now() + nextRetryMinutes * 60 * 1000).toISOString();

          await supabase
            .from("careflow_notifications")
            .update({
              fcm_status: "failed",
              next_retry_at: nextRetryDate,
            })
            .eq("id", notif.id);
        }
      }
    }

    const durationMs = Date.now() - startTime;
    return new Response(
      JSON.stringify({
        success: true,
        correlation_id: correlationId,
        duration_ms: durationMs,
        scheduler_run_at: new Date().toISOString(),
        claim_result: claimResult,
        events_processed: dispatchResults.length,
        dispatches: dispatchResults,
      }),
      { status: 200, headers: corsHeaders }
    );
  } catch (err: any) {
    console.error(`[${correlationId}] Scheduler unhandled exception:`, err);
    return new Response(
      JSON.stringify({
        error: err.message ?? "Unknown internal error",
        correlation_id: correlationId,
      }),
      { status: 500, headers: corsHeaders }
    );
  }
});
