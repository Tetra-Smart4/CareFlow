import { createClient } from "supabase";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });
}

Deno.serve(async (req: Request) => {
  // Handle browser preflight request
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      status: 200,
      headers: corsHeaders,
    });
  }

  if (req.method !== "POST") {
    return jsonResponse(
      {
        error: "Only POST requests are allowed.",
      },
      405,
    );
  }

  try {
    // 1. Read Supabase environment variables
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");

    if (!supabaseUrl || !serviceRoleKey || !anonKey) {
      return jsonResponse(
        {
          error: "Supabase server configuration is missing.",
        },
        500,
      );
    }

    // 2. Read the logged-in clinic's access token
    const authorization = req.headers.get("Authorization");
    if (!authorization) {
      return jsonResponse(
        {
          error: "Authorization header is required.",
        },
        401,
      );
    }

    const accessToken = authorization.replace(/^Bearer\s+/i, "").trim();
    if (!accessToken) {
      return jsonResponse(
        {
          error: "Invalid authorization token.",
        },
        401,
      );
    }

    // 3. Create client using the user's token
    const userClient = createClient(supabaseUrl, anonKey, {
      global: {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      },
    });

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser(accessToken);

    if (userError || !user) {
      return jsonResponse(
        {
          error: "Your login session is invalid or expired.",
        },
        401,
      );
    }

    // 4. Create service-role admin client
    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // 5. Verify that caller is a clinic
    const { data: clinicProfile, error: clinicProfileError } =
      await adminClient
        .from("profiles")
        .select("id, full_name, role, clinic_name")
        .eq("id", user.id)
        .maybeSingle();

    if (clinicProfileError) {
      return jsonResponse(
        {
          error: "Unable to verify clinic profile.",
          details: clinicProfileError.message,
        },
        500,
      );
    }

    if (!clinicProfile || clinicProfile.role !== "clinic") {
      return jsonResponse(
        {
          error: "Only authorized clinic accounts can manage doctors.",
        },
        403,
      );
    }

    // 6. Verify clinic exists AND is APPROVED
    const { data: clinic, error: clinicError } = await adminClient
      .from("clinics")
      .select("id, status, name")
      .eq("id", user.id)
      .maybeSingle();

    if (clinicError) {
      return jsonResponse(
        {
          error: "Unable to verify clinic records.",
          details: clinicError.message,
        },
        500,
      );
    }

    if (!clinic) {
      return jsonResponse(
        {
          error: "Clinic record was not found.",
        },
        403,
      );
    }

    if (clinic.status !== "approved") {
      return jsonResponse(
        {
          error:
            "Your clinic registration must be approved by the platform administrator before you can add doctors.",
        },
        403,
      );
    }

    // 7. Parse request body
    const body = await req.json().catch(() => ({}));
    const action = String(body.action ?? "create").trim();

    // Determine redirect URL for invitation email
    const reqOrigin =
      req.headers.get("origin") ||
      req.headers.get("referer") ||
      supabaseUrl;
    const cleanOrigin = reqOrigin.replace(/\/$/, "");
    const redirectTo = `${cleanOrigin}/#/auth/reset-password`;

    // ---------------------------------------------------------
    // ACTION: RESEND INVITATION
    // ---------------------------------------------------------
    if (action === "resend_invite") {
      const email = String(body.email ?? "").trim().toLowerCase();
      const doctorId = String(body.doctor_id ?? "").trim();

      if (!email && !doctorId) {
        return jsonResponse(
          { error: "Doctor email or ID is required to resend invitation." },
          400,
        );
      }

      // Check association
      let assocQuery = adminClient
        .from("clinic_doctors")
        .select("id, doctor_id, status")
        .eq("clinic_id", user.id);

      if (doctorId) {
        assocQuery = assocQuery.eq("doctor_id", doctorId);
      }

      const { data: assocList } = await assocQuery;
      if (!assocList || assocList.length === 0) {
        return jsonResponse(
          { error: "Doctor is not associated with your clinic." },
          404,
        );
      }

      const targetDoctorId = assocList[0].doctor_id;

      // Find doctor email if not provided
      let targetEmail = email;
      if (!targetEmail) {
        const { data: docProf } = await adminClient
          .from("profiles")
          .select("email")
          .eq("id", targetDoctorId)
          .maybeSingle();
        targetEmail = docProf?.email?.toLowerCase() ?? "";
      }

      if (!targetEmail) {
        // Fallback to auth.users lookup
        const {
          data: { user: authUser },
        } = await adminClient.auth.admin.getUserById(targetDoctorId);
        targetEmail = authUser?.email?.toLowerCase() ?? "";
      }

      if (!targetEmail) {
        return jsonResponse(
          { error: "Unable to locate doctor email address." },
          404,
        );
      }

      // Re-send invitation
      const { error: resendError } =
        await adminClient.auth.admin.inviteUserByEmail(targetEmail, {
          redirectTo,
        });

      if (resendError) {
        return jsonResponse(
          {
            error: "Unable to resend email invitation.",
            details: resendError.message,
          },
          400,
        );
      }

      await adminClient
        .from("clinic_doctors")
        .update({
          invited_at: new Date().toISOString(),
        })
        .eq("clinic_id", user.id)
        .eq("doctor_id", targetDoctorId);

      return jsonResponse({
        success: true,
        message: `Invitation email resent successfully to ${targetEmail}.`,
      });
    }

    // ---------------------------------------------------------
    // ACTION: CREATE / ONBOARD DOCTOR
    // ---------------------------------------------------------
    const fullName = String(body.full_name ?? "").trim();
    const email = String(body.email ?? "").trim().toLowerCase();
    const phone = String(body.phone ?? "").trim();
    const specialization = String(body.specialization ?? "").trim();
    const qualification = String(body.qualification ?? "").trim();
    const registrationNumber = String(
      body.registration_number ?? body.medical_registration ?? "",
    ).trim();

    const experience =
      body.experience === null ||
      body.experience === undefined ||
      body.experience === ""
        ? null
        : Number(body.experience);

    const consultationFee =
      body.consultation_fee === null ||
      body.consultation_fee === undefined ||
      body.consultation_fee === ""
        ? null
        : Number(body.consultation_fee);

    // Validation
    if (!fullName) {
      return jsonResponse({ error: "Doctor full name is required." }, 400);
    }

    if (!email) {
      return jsonResponse({ error: "Doctor email address is required." }, 400);
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return jsonResponse(
        { error: "Please provide a valid doctor email address." },
        400,
      );
    }

    if (!specialization) {
      return jsonResponse(
        { error: "Doctor specialization is required." },
        400,
      );
    }

    if (experience !== null && (!Number.isFinite(experience) || experience < 0)) {
      return jsonResponse(
        { error: "Experience must be a non-negative number of years." },
        400,
      );
    }

    if (
      consultationFee !== null &&
      (!Number.isFinite(consultationFee) || consultationFee < 0)
    ) {
      return jsonResponse(
        { error: "Consultation fee must be a valid positive amount." },
        400,
      );
    }

    // Check if an Auth account already exists with this email
    const {
      data: { users },
      error: listUsersError,
    } = await adminClient.auth.admin.listUsers({ page: 1, perPage: 1000 });

    if (listUsersError) {
      return jsonResponse(
        {
          error: "Failed to check existing accounts.",
          details: listUsersError.message,
        },
        500,
      );
    }

    const existingAuthUser = users.find(
      (u) => u.email?.toLowerCase() === email,
    );

    // ---------------------------------------------------------
    // CASE A: USER ALREADY EXISTS (ACCOUNT LINKING)
    // ---------------------------------------------------------
    if (existingAuthUser) {
      const existingUserId = existingAuthUser.id;

      // Verify existing profile role
      const { data: existingProfile } = await adminClient
        .from("profiles")
        .select("id, full_name, role, status")
        .eq("id", existingUserId)
        .maybeSingle();

      if (existingProfile && existingProfile.role !== "doctor") {
        return jsonResponse(
          {
            error: `The email ${email} is already registered under the role "${existingProfile.role}". A doctor cannot use this account.`,
          },
          400,
        );
      }

      // Check if already in clinic_doctors
      const { data: existingAssoc } = await adminClient
        .from("clinic_doctors")
        .select("id, active, status")
        .eq("clinic_id", user.id)
        .eq("doctor_id", existingUserId)
        .maybeSingle();

      if (existingAssoc) {
        if (existingAssoc.active && existingAssoc.status === "active") {
          return jsonResponse(
            {
              error:
                "This doctor is already actively associated with your clinic.",
            },
            400,
          );
        }

        // Reactivate existing association
        await adminClient
          .from("clinic_doctors")
          .update({
            active: true,
            status: "active",
            is_available: true,
            deactivated_at: null,
            consultation_fee: consultationFee,
          })
          .eq("id", existingAssoc.id);

        if (consultationFee !== null) {
          await adminClient.from("careflow_doctor_clinic_fees").upsert({
            clinic_id: user.id,
            doctor_id: existingUserId,
            approved_fee: consultationFee,
            proposed_fee: null,
            proposal_status: "none",
            updated_at: new Date().toISOString(),
          });
        }

        return jsonResponse({
          success: true,
          message: `Dr. ${existingProfile?.full_name ?? fullName} has been re-associated with your clinic successfully.`,
          doctor: {
            id: existingUserId,
            full_name: existingProfile?.full_name ?? fullName,
            email: email,
            phone: phone || null,
            specialization: specialization,
            qualification: qualification || null,
            experience: experience,
            consultation_fee: consultationFee,
            clinic_id: user.id,
            status: "active",
          },
        });
      }

      // Existing doctor not yet in clinic_doctors -> Link association
      await adminClient.from("clinic_doctors").insert({
        clinic_id: user.id,
        doctor_id: existingUserId,
        active: true,
        status: "active",
        is_available: true,
        consultation_fee: consultationFee,
      });

      if (consultationFee !== null) {
        await adminClient.from("careflow_doctor_clinic_fees").upsert({
          clinic_id: user.id,
          doctor_id: existingUserId,
          approved_fee: consultationFee,
          proposed_fee: null,
          proposal_status: "none",
          updated_at: new Date().toISOString(),
        });
      }

      // Notify the doctor in-app
      await adminClient.from("careflow_notifications").insert({
        user_id: existingUserId,
        title: "New Clinic Affiliation",
        body: `${clinic.name || "A clinic"} has added you to their medical team.`,
        type: "clinic_affiliation",
        is_read: false,
        created_at: new Date().toISOString(),
      });

      return jsonResponse({
        success: true,
        message: `Dr. ${existingProfile?.full_name ?? fullName} is already registered on CareFlow and has now been successfully linked to your clinic.`,
        doctor: {
          id: existingUserId,
          full_name: existingProfile?.full_name ?? fullName,
          email: email,
          phone: phone || null,
          specialization: specialization,
          qualification: qualification || null,
          experience: experience,
          consultation_fee: consultationFee,
          clinic_id: user.id,
          status: "active",
        },
      });
    }

    // ---------------------------------------------------------
    // CASE B: NEW DOCTOR INVITATION
    // ---------------------------------------------------------
    const { data: invitedUser, error: inviteError } =
      await adminClient.auth.admin.inviteUserByEmail(email, {
        redirectTo,
        data: {
          full_name: fullName,
          role: "doctor",
        },
      });

    if (inviteError || !invitedUser.user) {
      return jsonResponse(
        {
          error: "Unable to send invitation to doctor.",
          details: inviteError?.message ?? "Unknown error.",
        },
        400,
      );
    }

    const doctorUserId = invitedUser.user.id;

    // 10. Upsert doctor profile (status: invited)
    const { error: profileError } = await adminClient
      .from("profiles")
      .upsert({
        id: doctorUserId,
        full_name: fullName,
        email: email,
        role: "doctor",
        phone: phone || null,
        qualification: qualification || null,
        registration_number: registrationNumber || null,
        status: "invited",
      });

    if (profileError) {
      await adminClient.auth.admin.deleteUser(doctorUserId);
      return jsonResponse(
        {
          error: "Unable to create doctor profile.",
          details: profileError.message,
        },
        500,
      );
    }

    // 11. Generate internal doctor ID
    const internalDoctorId = `DOC-${crypto
      .randomUUID()
      .replaceAll("-", "")
      .slice(0, 8)
      .toUpperCase()}`;

    // 12. Create doctor record in public.doctors
    const { error: doctorError } = await adminClient.from("doctors").upsert({
      id: doctorUserId,
      doctor_id: internalDoctorId,
      specialization: specialization,
      qualification: qualification || null,
      experience: experience,
      registration_number: registrationNumber || null,
      consultation_fee: consultationFee,
      is_available: false,
    });

    if (doctorError) {
      await adminClient.from("profiles").delete().eq("id", doctorUserId);
      await adminClient.auth.admin.deleteUser(doctorUserId);
      return jsonResponse(
        {
          error: "Unable to create doctor record.",
          details: doctorError.message,
        },
        500,
      );
    }

    // 13. Create clinic_doctors association (status: invited)
    const { error: assignmentError } = await adminClient
      .from("clinic_doctors")
      .upsert({
        clinic_id: user.id,
        doctor_id: doctorUserId,
        active: true,
        status: "invited",
        is_available: false,
        consultation_fee: consultationFee,
        invited_at: new Date().toISOString(),
      });

    if (assignmentError) {
      await adminClient.from("doctors").delete().eq("id", doctorUserId);
      await adminClient.from("profiles").delete().eq("id", doctorUserId);
      await adminClient.auth.admin.deleteUser(doctorUserId);
      return jsonResponse(
        {
          error: "Unable to link doctor to clinic.",
          details: assignmentError.message,
        },
        500,
      );
    }

    // 14. Create initial fee record
    if (consultationFee !== null) {
      await adminClient.from("careflow_doctor_clinic_fees").upsert({
        clinic_id: user.id,
        doctor_id: doctorUserId,
        approved_fee: consultationFee,
        proposed_fee: null,
        proposal_status: "none",
        updated_at: new Date().toISOString(),
      });

      await adminClient.from("careflow_doctor_clinic_fee_history").insert({
        clinic_id: user.id,
        doctor_id: doctorUserId,
        fee: consultationFee,
        action: "initial_set",
        actor_id: user.id,
        notes: "Initial consultation fee set during doctor invitation.",
      });
    }

    // 15. Audit log
    await adminClient.from("careflow_audit_logs").insert({
      actor_id: user.id,
      action: "DOCTOR_INVITED",
      resource_type: "clinic_doctors",
      resource_id: doctorUserId,
      metadata: {
        clinic_id: user.id,
        email: email,
        specialization: specialization,
      },
    });

    // 16. Success response
    return jsonResponse({
      success: true,
      message: `Doctor invited successfully. An account activation invitation email has been dispatched to ${email}.`,
      doctor: {
        id: doctorUserId,
        doctor_id: internalDoctorId,
        full_name: fullName,
        email: email,
        phone: phone || null,
        specialization: specialization,
        qualification: qualification || null,
        experience: experience,
        registration_number: registrationNumber || null,
        consultation_fee: consultationFee,
        clinic_id: user.id,
        status: "invited",
      },
    });
  } catch (error) {
    return jsonResponse(
      {
        error: "Unexpected server error.",
        details:
          error instanceof Error ? error.message : String(error),
      },
      500,
    );
  }
});