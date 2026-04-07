import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-queue-secret",
};

type QueueRow = {
  id: number;
  event_type: string;
  source_table: string;
  source_id: string;
  recipient_role: string;
  recipient_phone: string;
  message: string;
  image_url: string | null;
  retry_count: number;
  max_retries: number;
};

const normalizedBaseUrl = (Deno.env.get("WA_API_BASE_URL") ?? "").replace(
  /\/+$/,
  "",
);
const username = Deno.env.get("WA_API_USERNAME") ?? "";
const password = Deno.env.get("WA_API_PASSWORD") ?? "";
const deviceId = Deno.env.get("WA_API_DEVICE_ID") ?? "";
const queueSecret = Deno.env.get("WA_QUEUE_SECRET") ?? "";
const MAX_ERROR_BODY_LENGTH = 300;

function apiHeaders(contentType?: string): HeadersInit {
  const headers: Record<string, string> = {
    Authorization: `Basic ${btoa(`${username}:${password}`)}`,
  };
  if (deviceId) headers["X-Device-Id"] = deviceId;
  if (contentType) headers["Content-Type"] = contentType;
  return headers;
}

function retryDelayMinutes(retryCount: number): number {
  // Exponential backoff (1, 2, 4, 8, ...) capped at 60 minutes.
  return Math.min(2 ** Math.max(retryCount, 0), 60);
}

function filenameFromContentType(contentType: string | null): string {
  if (!contentType) return "proof.jpg";
  if (contentType.includes("png")) return "proof.png";
  if (contentType.includes("webp")) return "proof.webp";
  if (contentType.includes("gif")) return "proof.gif";
  return "proof.jpg";
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (queueSecret && req.headers.get("x-queue-secret") !== queueSecret) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (!normalizedBaseUrl || !username || !password) {
    return new Response(
      JSON.stringify({
        error:
          "Missing WA API configuration. Set WA_API_BASE_URL, WA_API_USERNAME, WA_API_PASSWORD.",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { autoRefreshToken: false, persistSession: false } },
    );

    let batchSize = 20;
    try {
      const body = await req.json();
      if (typeof body?.batch_size === "number" && body.batch_size > 0) {
        batchSize = Math.min(Math.floor(body.batch_size), 100);
      }
    } catch {
      // empty body is allowed
    }

    const { data: queueRows, error: dequeueError } = await supabase.rpc(
      "dequeue_wa_notifications",
      { p_batch_size: batchSize },
    );

    if (dequeueError) {
      throw dequeueError;
    }

    const rows = (queueRows ?? []) as QueueRow[];
    if (!rows.length) {
      return new Response(
        JSON.stringify({ success: true, processed: 0, sent: 0, failed: 0 }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const statusResponse = await fetch(`${normalizedBaseUrl}/app/status`, {
      method: "GET",
      headers: apiHeaders(),
    });
    const statusText = await statusResponse.text();

    await supabase.from("wa_notification_logs").insert({
      endpoint: "/app/status",
      request_payload: { source: "process-wa-notification-queue" },
      response_status: statusResponse.status,
      response_body: statusText,
      success: statusResponse.ok,
      error_message: statusResponse.ok ? null : "WA gateway status check failed",
    });

    if (!statusResponse.ok) {
      const errorMessage = `WA gateway unavailable: ${statusResponse.status} ${statusText}`;

      await Promise.all(
        rows.map((row) =>
          supabase
            .from("wa_notification_queue")
            .update({
              status: row.retry_count + 1 >= row.max_retries ? "failed" : "pending",
              retry_count: row.retry_count + 1,
              next_attempt_at: new Date(
                Date.now() + retryDelayMinutes(row.retry_count + 1) * 60_000,
              ).toISOString(),
              last_error: errorMessage,
              processed_at: row.retry_count + 1 >= row.max_retries
                ? new Date().toISOString()
                : null,
            })
            .eq("id", row.id)
            .eq("status", "processing"),
        ),
      );

      return new Response(
        JSON.stringify({
          success: false,
          processed: rows.length,
          sent: 0,
          failed: rows.length,
          error: errorMessage,
        }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    let sent = 0;
    let failed = 0;

    for (const row of rows) {
      try {
        let response: Response;
        let endpoint: string;
        let requestPayload: Record<string, unknown>;

        if (row.image_url) {
          endpoint = "/send/image";
          const imageResponse = await fetch(row.image_url);
          if (!imageResponse.ok) {
            const imageErrorBody = (await imageResponse.text()).slice(
              0,
              MAX_ERROR_BODY_LENGTH,
            );
            throw new Error(
              `Failed to download proof image: ${imageResponse.status} ${imageResponse.statusText} ${imageErrorBody}`,
            );
          }
          const imageBlob = await imageResponse.blob();
          const imageFilename = filenameFromContentType(
            imageResponse.headers.get("content-type"),
          );
          const formData = new FormData();
          formData.append("phone", row.recipient_phone);
          formData.append("image", imageBlob, imageFilename);
          formData.append("caption", row.message);

          requestPayload = {
            phone: row.recipient_phone,
            image_url: row.image_url,
            caption: row.message,
          };
          response = await fetch(`${normalizedBaseUrl}${endpoint}`, {
            method: "POST",
            headers: apiHeaders(),
            body: formData,
          });
        } else {
          endpoint = "/send/message";
          requestPayload = {
            phone: row.recipient_phone,
            message: row.message,
          };
          response = await fetch(`${normalizedBaseUrl}${endpoint}`, {
            method: "POST",
            headers: apiHeaders("application/json"),
            body: JSON.stringify(requestPayload),
          });
        }

        const responseBody = await response.text();
        const isSuccess = response.ok;

        await supabase.from("wa_notification_logs").insert({
          queue_id: row.id,
          endpoint,
          request_payload: requestPayload,
          response_status: response.status,
          response_body: responseBody,
          success: isSuccess,
          error_message: isSuccess ? null : responseBody,
        });

        if (isSuccess) {
          sent += 1;
          await supabase
            .from("wa_notification_queue")
            .update({
              status: "sent",
              processed_at: new Date().toISOString(),
              last_error: null,
            })
            .eq("id", row.id)
            .eq("status", "processing");
        } else {
          failed += 1;
          const nextRetryCount = row.retry_count + 1;
          await supabase
            .from("wa_notification_queue")
            .update({
              status: nextRetryCount >= row.max_retries ? "failed" : "pending",
              retry_count: nextRetryCount,
              next_attempt_at: new Date(
                Date.now() + retryDelayMinutes(nextRetryCount) * 60_000,
              ).toISOString(),
              last_error: responseBody,
              processed_at: nextRetryCount >= row.max_retries
                ? new Date().toISOString()
                : null,
            })
            .eq("id", row.id)
            .eq("status", "processing");
        }
      } catch (error) {
        failed += 1;
        const nextRetryCount = row.retry_count + 1;
        const errorMessage = error instanceof Error ? error.message : String(error);

        await supabase.from("wa_notification_logs").insert({
          queue_id: row.id,
          endpoint: row.image_url ? "/send/image" : "/send/message",
          request_payload: {
            phone: row.recipient_phone,
            message: row.message,
            image_url: row.image_url,
          },
          success: false,
          error_message: errorMessage,
        });

        await supabase
          .from("wa_notification_queue")
          .update({
            status: nextRetryCount >= row.max_retries ? "failed" : "pending",
            retry_count: nextRetryCount,
            next_attempt_at: new Date(
              Date.now() + retryDelayMinutes(nextRetryCount) * 60_000,
            ).toISOString(),
            last_error: errorMessage,
            processed_at: nextRetryCount >= row.max_retries
              ? new Date().toISOString()
              : null,
          })
          .eq("id", row.id)
          .eq("status", "processing");
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        processed: rows.length,
        sent,
        failed,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("process-wa-notification-queue failed", error);
    return new Response(
      JSON.stringify({
        error: "Unexpected error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
