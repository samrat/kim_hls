defmodule HLS.Playlist.Media.BuilderTest do
  use ExUnit.Case

  alias HLS.Playlist.Media.Builder
  alias HLS.Playlist.Media
  alias HLS.Segment

  test "fits one payload in the future" do
    playlist = Media.new(URI.new!("/data/media.m3u8"), 3)

    builder =
      playlist
      |> Builder.new(".ts")
      # Buffers are allowed to start in a segment and finish in the other one.
      |> Builder.fit(%{from: 4, to: 6, payload: <<>>})
      |> Builder.flush()

    playlist = Builder.playlist(builder)
    segments = Media.segments(playlist)

    assert length(segments) == 2
    assert Media.compute_playlist_duration(playlist) == 6
    assert Enum.map(segments, fn %Segment{absolute_sequence: x} -> x end) == [0, 1]
    refute Enum.any?(segments, fn %Segment{uri: x} -> x == nil end)
  end

  test "take uploadables" do
    playlist = Media.new(URI.new!("http://example.com/data/media.m3u8"), 3)

    builder =
      playlist
      |> Builder.new(".ts")
      # Buffers are allowed to start in a segment and finish in the other one.
      |> Builder.fit(%{from: 1, to: 2, payload: "a"})
      |> Builder.fit(%{from: 2, to: 3, payload: "b"})
      # This buffer triggers a segment window switch forward, hence the previous
      # one is considered complete.
      |> Builder.fit(%{from: 3, to: 5, payload: "c"})

    {uploadables, builder} = Builder.take_uploadables(builder)
    assert length(uploadables) == 1

    assert %{payload: ["a", "b"], uri: URI.new!("http://example.com/data/media/00000.ts")} ==
             List.first(uploadables)

    playlist = Builder.playlist(builder)
    segments = Media.segments(playlist)

    # The other one is still pending.
    assert length(segments) == 1
  end
end