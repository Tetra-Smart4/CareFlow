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
  // Handle browser preflight request.
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
    // ---------------------------------------------------------
    // 1. Read Supabase environment variables
    // ---------------------------------------------------------

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

    // ---------------------------------------------------------
    // 2. Read the logged-in clinic's access token
    // ---------------------------------------------------------

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

    // ---------------------------------------------------------
    // 3. Create client using the user's token
    // ---------------------------------------------------------

    const userClient = createClient(
      supabaseUrl,
      anonKey,
      {
        global: {
          headers: {
            Authorization: `Bearer ${accessToken}`,
          },
        },
      },
    );

    const {
      data: {
        user,
      },
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

    // ---------------------------------------------------------
    // 4. Create service-role client
    //
    // This client is ONLY inside the Edge Function.
    // It must NEVER be placed inside Flutter.
    // ---------------------------------------------------------

    const adminClient = createClient(
      supabaseUrl,
      serviceRoleKey,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      },
    );

    // ---------------------------------------------------------
    // 5. Verify that the caller is a clinic
    // ---------------------------------------------------------

    const {
      data: clinicProfile,
      error: clinicProfileError,
    } = await adminClient
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

    if (!clinicProfile) {
      return jsonResponse(
        {
          error: "Clinic profile not found.",
        },
        403,
      );
    }

    if (clinicProfile.role !== "clinic") {
      return jsonResponse(
        {
          error: "Only clinic accounts can add doctors.",
        },
        403,
      );
    }

    // ---------------------------------------------------------
    // 6. Verify that the clinic exists
    // ---------------------------------------------------------

    const {
      data: clinic,
      error: clinicError,
    } = await adminClient
      .from("clinics")
      .select("id")
      .eq("id", user.id)
      .maybeSingle();

    if (clinicError) {
      return jsonResponse(
        {
          error: "Unable to verify clinic.",
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

    // ---------------------------------------------------------
    // 7. Read doctor information from request
    // ---------------------------------------------------------

    const body = await req.json();

    const fullName = String(body.full_name ?? "").trim();
    const email = String(body.email ?? "").trim().toLowerCase();
    const phone = String(body.phone ?? "").trim();
    const specialization = String(body.specialization ?? "").trim();
    const qualification = String(body.qualification ?? "").trim();

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

    // ---------------------------------------------------------
    // 8. Validate required fields
    // ---------------------------------------------------------

    if (!fullName) {
      return jsonResponse(
        {
          error: "Doctor name is required.",
        },
        400,
      );
    }

    if (!email) {
      return jsonResponse(
        {
          error: "Doctor email is required.",
        },
        400,
      );
    }

    if (!specialization) {
      return jsonResponse(
        {
          error: "Doctor specialization is required.",
        },
        400,
      );
    }

    if (experience !== null && !Number.isFinite(experience)) {
      return jsonResponse(
        {
          error: "Experience must be a valid number.",
        },
        400,
      );
    }

    if (
      consultationFee !== null &&
      !Number.isFinite(consultationFee)
    ) {
      return jsonResponse(
        {
          error: "Consultation fee must be a valid number.",
        },
        400,
      );
    }

    // ---------------------------------------------------------
    // 9. Create / invite doctor's Supabase Auth account
    // ---------------------------------------------------------

    const {
      data: invitedUser,
      error: inviteError,
    } = await adminClient.auth.admin.inviteUserByEmail(email);

    if (inviteError || !invitedUser.user) {
      return jsonResponse(
        {
          error: "Unable to create doctor account.",
          details: inviteError?.message ?? "Unknown error.",
        },
        400,
      );
    }

    const doctorUserId = invitedUser.user.id;

    // ---------------------------------------------------------
    // 10. Create doctor profile
    // ---------------------------------------------------------

    const { error: profileInsertError } = await adminClient
      .from("profiles")
      .insert({
        id: doctorUserId,
        full_name: fullName,
        role: "doctor",
        phone: phone || null,
      });

    if (profileInsertError) {
      await adminClient.auth.admin.deleteUser(doctorUserId);

      return jsonResponse(
        {
          error: "Unable to create doctor profile.",
          details: profileInsertError.message,
        },
        400,
      );
    }

    // ---------------------------------------------------------
    // 11. Generate internal doctor ID
    // ---------------------------------------------------------

    const doctorId =
      `DOC-${crypto.randomUUID().replaceAll("-", "").slice(0, 8).toUpperCase()}`;

    // ---------------------------------------------------------
    // 12. Create doctor record
    // ---------------------------------------------------------

    const { error: doctorInsertError } = await adminClient
      .from("doctors")
      .insert({
        id: doctorUserId,
        doctor_id: doctorId,
        specialization: specialization,
        qualification: qualification || null,
        experience: experience,
        consultation_fee: consultationFee,
        is_available: true,
      });

    if (doctorInsertError) {
      await adminClient
        .from("profiles")
        .delete()
        .eq("id", doctorUserId);

      await adminClient.auth.admin.deleteUser(doctorUserId);

      return jsonResponse(
        {
          error: "Unable to create doctor record.",
          details: doctorInsertError.message,
        },
        400,
      );
    }

    // ---------------------------------------------------------
    // 13. Assign doctor to the clinic
    // ---------------------------------------------------------

    const { error: assignmentError } = await adminClient
      .from("clinic_doctors")
      .insert({
        clinic_id: user.id,
        doctor_id: doctorUserId,
        active: true,
        is_available: true,
      });

    if (assignmentError) {
      await adminClient
        .from("doctors")
        .delete()
        .eq("id", doctorUserId);

      await adminClient
        .from("profiles")
        .delete()
        .eq("id", doctorUserId);

      await adminClient.auth.admin.deleteUser(doctorUserId);

      return jsonResponse(
        {
          error: "Unable to assign doctor to clinic.",
          details: assignmentError.message,
        },
        400,
      );
    }

    // ---------------------------------------------------------
    // 14. Success
    // ---------------------------------------------------------

    return jsonResponse({
      success: true,

      message: "Doctor created and assigned to the clinic successfully.",
      doctor: {
        id: doctorUserId,
        doctor_id: doctorId,
        full_name: fullName,
        email: email,
        phone: phone || null,
        specialization: specialization,
        qualification: qualification || null,
        experience: experience,
        consultation_fee: consultationFee,
        clinic_id: user.id,
      },
    });
  } catch (error) {
    return jsonResponse(
      {
        error: "Unexpected server error.",
        details:
          error instanceof Error
            ? error.message
            : String(error),
      },
      500,
    );
  }
});