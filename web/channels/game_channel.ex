defmodule HelloPhoenix.GameChannel do
  use Phoenix.Channel

  intercept [ "start", "make_move" ]

  def join("games:lobby", message, socket) do
    {:ok, redis_client} = Exredis.start_link

    uuid = socket.assigns[ :uuid ]
    IO.puts "join, uuid=#{uuid}"
    opponent = redis_client |> Exredis.query(["SPOP", "seeks"])

    if opponent == :undefined do
      redis_client |> Exredis.query(["SADD", "seeks", uuid])
    else
      socket = assign( socket, :player_1, opponent )
      socket = assign( socket, :player_2, uuid)

      IO.puts "socket.id = #{socket.id}"
      IO.puts "player_1 = #{socket.assigns[ :player_1 ]}"
      IO.inspect socket.assigns[ :player_1 ]
      IO.puts "player_2 = #{socket.assigns[ :player_2 ]}"
      IO.inspect socket.assigns[ :player_2 ]

      send(self, :start_game)
    end
    {:ok, socket}
  end

  def handle_in("make_move", %{"color" => color, "flags" => flags, "from" => from, "piece" => piece, "san" => san, "to" => to}, socket) do
    broadcast! socket, "make_move", %{"color" => color, "flags" => flags, "from" => from, "piece" => piece, "san" => san, "to" => to}
    {:noreply, socket}
  end

  # def handle_in("start", %{"color" => color, "uuid" => uuid}, socket) do
  #   broadcast! socket, "start", %{"color" => color, "uuid" => uuid}
  #   IO.puts "handle_in: start color: #{color} uuid: #{uuid}"
  #   {:noreply, socket}
  # end

  def handle_info(:start_game, socket) do
    {:ok, redis_client} = Exredis.start_link
    redis_client |> Exredis.query(["DEL", "seeks"])

    broadcast! socket, "start", %{color: "white", uuid: socket.assigns[ :player_1 ]}
    broadcast! socket, "start", %{color: "black", uuid: socket.assigns[ :player_2 ]}
    {:noreply, socket}
  end

  def handle_out("start", payload = %{ color: _color, uuid: uuid }, socket) do
    IO.puts "uuid = #{uuid}"

    if socket.assigns[ :uuid ] == uuid do
      push socket, "start", payload
    end
    {:noreply, socket}
  end

  def handle_out("make_move", payload, socket) do
    push socket, "make_move", payload
    {:noreply, socket}
  end
end