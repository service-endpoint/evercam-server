defmodule Permissions.Camera do

  def can_edit?(requester, camera) do
    can_access?("edit", requester, camera)
  end

  def can_view?(requester, camera) do
    can_access?("view", requester, camera)
  end

  def can_snapshot?(requester, camera) do
    can_access?("snapshot", requester, camera)
  end

  def can_delete?(requester, camera) do
    can_access?("delete", requester, camera)
  end

  def can_list?(requester, camera) do
    can_access?("list", requester, camera)
  end

  def can_grant?(requester, camera) do
    can_access?("grant", requester, camera)
  end

  defp can_access?(right, requester, camera) do
    is_public?(right, camera) or is_owner?(requester, camera) or has_right?(right, requester, camera)
  end

  defp has_right?(_right, nil, _camera), do: false

  defp has_right?(right, %User{}, camera) do
    Enum.any?(camera.access_rights, fn(ar) -> ar.right == right end)
  end

  defp has_right?(right, %AccessToken{} = token, camera) do
    has_camera_right?(right, token, camera) || has_account_right?(right, token, camera)
    true
  end

  defp has_camera_right?(right, token, camera) do
    Enum.any?(camera.access_rights, fn(ar) ->
      ar.right == right &&
        ar.token_id == token.id &&
        ar.camera_id == camera.id &&
        ar.status == 1
    end)
  end

  defp has_account_right?(right, token, camera) do
    Enum.any?(camera.access_rights, fn(ar) ->
      ar.right == right &&
        ar.account_id == token.grantor_id &&
        ar.token_id == token.id &&
        ar.camera_id == camera.id &&
        ar.scope == "cameras" &&
        ar.status == 1
    end)
  end

  def is_owner?(nil, _camera), do: false
  def is_owner?(user, camera) do
    user.id == camera.owner_id
  end

  defp is_public?(right, camera) do
    case right do
      "snapshot" -> camera.is_public
      "list" -> camera.is_public
      _right -> false
    end
  end
end
