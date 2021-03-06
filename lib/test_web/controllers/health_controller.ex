defmodule TestWeb.HealthController do
  use TestWeb, :controller
  require Logger

  def healthz(conn, _params) do
    if Test.Database.available?() do
      healthy(conn)
    else
      vsn = Application.spec(:test, :vsn)
      degraded(conn, %{database: :down, version: "#{inspect vsn}"})
    end
  rescue
    err ->
      failed(conn, Exception.message(err))
  end

  defp healthy(conn) do 
    status = %{status: :ok}
    Logger.info "Health check good: #{inspect status}"
    json(conn, status)
  end

  defp degraded(conn, services) do
    status = %{status: :degraded, services: services}
    Logger.warn "Health check degraded: #{inspect status}"
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(500, Jason.encode!(status))
  end

  defp failed(conn, msg) do
    status = %{status: :error, message: msg}
    Logger.error "Health check failed: #{msg}"
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(500, Jason.encode!(status))
  end
end
