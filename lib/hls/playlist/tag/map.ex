defmodule HLS.Playlist.Tag.Map do
  use HLS.Playlist.Tag, id: :ext_x_map

  @impl true
  def unmarshal(line) do
    line
    |> capture_attribute_list!(fn
      "URI", value ->
        {:uri, value}

      "BYTERANGE", value ->
        {:byterange, value}

      _key, _value ->
        :skip
    end)
  end
end