defmodule HelloPhoenix.GameChannel do
  use Phoenix.Channel

  intercept [ "start", "make_move", "message" ]

  def join("games:lobby", _message, socket) do
    {:ok, redis_client} = Exredis.start_link

    uuid = socket.assigns[ :uuid ]
    opponent = redis_client |> Exredis.query(["SPOP", "seeks"])

    if opponent == :undefined do
      redis_client |> Exredis.query(["SADD", "seeks", uuid])
    else
      socket = assign( socket, :player_1, opponent )
      socket = assign( socket, :player_2, uuid)

      send(self, :start_game)
    end
    {:ok, socket}
  end

  def handle_in("make_move", %{"color" => color, "flags" => flags, "from" => from, "piece" => piece, "san" => san, "to" => to}, socket) do
    broadcast! socket, "make_move", %{"color" => color, "flags" => flags, "from" => from, "piece" => piece, "san" => san, "to" => to}
    {:noreply, socket}
  end

  def handle_info(:start_game, socket) do
    {:ok, redis_client} = Exredis.start_link
    redis_client |> Exredis.query(["DEL", "seeks"])

    player_1 = socket.assigns[ :player_1 ]
    player_2 = socket.assigns[ :player_2 ]

    redis_client |> Exredis.query(["SET", "opponent_for_#{player_1}", player_2])
    redis_client |> Exredis.query(["SET", "opponent_for_#{player_2}", player_1])

    broadcast! socket, "start", %{color: "white", uuid: player_1 }
    broadcast! socket, "start", %{color: "black", uuid: player_2 }
    {:noreply, socket}
  end

  def handle_out("start", payload = %{ color: _color, uuid: uuid }, socket) do
    if socket.assigns[ :uuid ] == uuid do
      push socket, "start", payload
    end
    {:noreply, socket}
  end

  def handle_out("make_move", payload, socket) do
    push socket, "make_move", payload
    {:noreply, socket}
  end

  def handle_out( "message", payload = %{ text: _text, uuid: uuid }, socket ) do
    if socket.assigns[ :uuid ] == uuid do
      push socket, "message", payload
    end
    {:noreply, socket}
  end

  def terminate( _reason, socket ) do
    # Logger.debug"> leave #{inspect reason}"
    uuid = socket.assigns[ :uuid ]
    
    {:ok, redis_client} = Exredis.start_link    
    other_player = redis_client |> Exredis.query(["GET", "opponent_for_#{uuid}" ])
    
    # Removes the redis opponent records when game is forfeit
    redis_client |> Exredis.query(["DEL", "opponent_for_#{uuid}" ])
    redis_client |> Exredis.query(["DEL", "opponent_for_#{other_player}" ])

    broadcast! socket, "message", %{text: "Opponent terminated, you win!", uuid: other_player }
    :ok
  end

end