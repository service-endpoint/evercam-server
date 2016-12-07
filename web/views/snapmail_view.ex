defmodule EvercamMedia.SnapmailView do
  use EvercamMedia.Web, :view
  alias EvercamMedia.Util

  def render("index.json", %{snapmails: snapmails}) do
    %{snapmails: render_many(snapmails, __MODULE__, "snapmail.json")}
  end

  def render("show.json", %{snapmail: nil}), do: %{snapmails: []}
  def render("show.json", %{snapmail: snapmail}) do
    %{snapmails: render_many([snapmail], __MODULE__, "snapmail.json")}
  end

  def render("snapmail.json", %{snapmail: snapmail}) do
    %{
      id: snapmail.exid,
      camera_id: snapmail.camera.exid,
      title: snapmail.subject,
      recipients: snapmail.recipients,
      message: snapmail.message,
      notify_days: snapmail.notify_days,
      notify_time: snapmail.notify_time,
      requested_by: Util.deep_get(snapmail, [:user, :username], ""),
      requester_name: User.get_fullname(snapmail.user),
      requester_email: Util.deep_get(snapmail, [:user, :email], ""),
      public: snapmail.is_public,
      created_at: Util.ecto_datetime_to_unix(snapmail.inserted_at)
    }
  end
end
