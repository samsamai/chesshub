defmodule HelloPhoenix.GameChannel do
  use Phoenix.Channel
  use Phoenix.Socket

  intercept ["start"]

  def join("games:lobby", message, socket) do
      IO.puts message[ "uuid" ]

      IO.puts "test player_1: #{socket.assigns[:player_1]}"

      if !socket.assigns[:player_1] do
        socket = assign( socket, :player_1, message[ "uuid" ] )
        socket = assign( socket, :player_1, 1234 )

        IO.puts "player_1: #{socket.assigns[:player_1]}"
      else
        socket = assign( socket, :player_2, message[ "uuid" ] )
        # start the game
        send(self, :after_join)
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

  def handle_info(:after_join, socket) do
    IO.puts "player_2: #{socket.assigns[:player_2]}"
    broadcast! socket, "start", %{"color" => "white", "uuid" => socket.assigns[:player_1]}
    broadcast! socket, "start", %{"color" => "black", "uuid" => socket.assigns[:player_2]}
    # push socket, "start", %{"color" => "black", "uuid" => socket.assigns[:player_2]}
    {:noreply, socket}
  end

  def handle_out("start", payload, socket) do
    IO.puts "handle_out: start #{payload}"

    push socket, "start", payload
    {:noreply, socket}
  end

  def handle_out("make_move", payload, socket) do
    IO.puts "handle_out: make_move #{payload}"

    push socket, "make_move", payload
    {:noreply, socket}
  end
end