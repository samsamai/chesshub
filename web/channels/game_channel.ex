defmodule HelloPhoenix.GameChannel do
  use Phoenix.Channel
  use Phoenix.Socket
  import Exredis.Api

  intercept ["start", "make_move"]

  def join("games:lobby", message, socket) do
    {:ok, redis_client} = Exredis.start_link

    # client |> Exredis.query ["SET", "FOO", "BAR"]
    player_1 = redis_client |> Exredis.query(["GET", "player_1"])

    IO.puts "join, message: #{message.uuid}"
    IO.puts "player_1"
    IO.inspect player_1

    if player_1 == :undefined do
      # socket = assign( socket, :player_1, message.uuid )
      redis_client |> Exredis.query(["SET", "player_1", message.uuid])

    else
      IO.puts "Setting player 2"
      redis_client |> Exredis.query(["SET", "player_2", message.uuid])

      # socket = assign( socket, :player_2, message.uuid )
      # start the game
      send(self, :start_game)
    end
    {:ok, socket}
  end

  def handle_in("make_move", %{"color" => color, "flags" => flags, "from" => from, "piece" => piece, "san" => san, "to" => to}, socket) do
    broadcast! socket, "make_move", %{"color" => color, "flags" => flags, "from" => from, "piece" => piece, "san" => san, "to" => to}
    IO.puts "handle_in: make_move color: #{color} from: #{from}"
    {:noreply, socket}
  end

  # def handle_in("start", %{"color" => color, "uuid" => uuid}, socket) do
  #   broadcast! socket, "start", %{"color" => color, "uuid" => uuid}
  #   IO.puts "handle_in: start color: #{color} uuid: #{uuid}"
  #   {:noreply, socket}
  # end

  def handle_info(:start_game, socket) do
    {:ok, redis_client} = Exredis.start_link
    player_1 = redis_client |> Exredis.query(["GET", "player_1"])
    player_2 = redis_client |> Exredis.query(["GET", "player_2"])

    IO.puts "handle_info, start_game"
    IO.inspect player_1
    IO.inspect player_2
    broadcast! socket, "start", %{"color" => "white", "uuid" => player_1}
    broadcast! socket, "start", %{"color" => "black", "uuid" => player_2}
    # push socket, "start", %{"color" => "black", "uuid" => socket.assigns[:player_2]}
    {:noreply, socket}
  end

  def handle_out("start", payload, socket) do
    IO.puts "handle_out: start #{payload}"

    push socket, "start", payload
    {:noreply, socket}
  end

  def handle_out("make_move", payload, socket) do
    push socket, "make_move", payload
    {:noreply, socket}
  end
end