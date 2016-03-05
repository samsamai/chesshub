defmodule HelloPhoenix.GameChannelTest do
  use HelloPhoenix.ChannelCase

  alias HelloPhoenix.GameChannel

  setup do
    {:ok, redis_client} = Exredis.start_link
    redis_client |> Exredis.query(["DEL", "seeks"])

    {:ok, _, socket} =
      socket("socket_id_1", %{ uuid: "socket_id_1" })
      |> subscribe_and_join(GameChannel, "games:lobby", %{})

    {:ok, socket: socket}
  end

  test "make_move broadcasts to games:lobby", %{socket: socket} do
    payload = %{"color" => "white", "flags" => "flags", "from" => "d2", "piece" => "p", "san" => "san", "to" => "d4"}
    push socket, "make_move", payload
    assert_broadcast "make_move", payload
  end

  test "make_move broadcasts are pushed to the client", %{socket: socket} do
    payload = %{"color" => "white", "from" => "d2", "piece" => "p", "san" => "san", "to" => "d4"}

    broadcast_from! socket, "make_move", payload
    assert_push "make_move", payload
  end

  test "start_game should broadcast start for each color", %{socket: socket} do
    send(socket.channel_pid, :start_game)

    assert_broadcast "start", %{ color: "white", uuid: _}
    assert_broadcast "start", %{ color: "black", uuid: _}
  end

  test "joining creates a seek in redis" do
    {:ok, redis_client} = Exredis.start_link
    [ player_1 | _ ] = redis_client |> Exredis.query(["SMEMBERS", "seeks"])
    assert "socket_id_1" == player_1
  end

  test "second join should set player_2 in redis" do
    {:ok, redis_client} = Exredis.start_link
    redis_client |> Exredis.query(["DEL", "seeks"])

    socket("socket_id_1", %{ uuid: "socket_id_1"})
      |> subscribe_and_join(GameChannel, "games:lobby", %{})
    
    socket("socket_id_2", %{ uuid: "socket_id_2"})
      |> subscribe_and_join(GameChannel, "games:lobby", %{})

    assert_broadcast "start", %{ color: "white", uuid: "socket_id_1" }
    assert_broadcast "start", %{ color: "black", uuid: "socket_id_2" }
  end

  test "start_game should push to each socket", %{socket: socket} do
    {:ok, redis_client} = Exredis.start_link
    [ player_1 | _ ] = redis_client |> Exredis.query(["SMEMBERS", "seeks"])
    assert "socket_id_1" == player_1

    {:ok, redis_client} = Exredis.start_link
    redis_client |> Exredis.query(["DEL", "seeks"])

    socket("socket_id_1", %{uuid: "socket_id_1"})
      |> subscribe_and_join(GameChannel, "games:lobby", %{})
    
    socket("socket_id_2", %{uuid: "socket_id_2"})
      |> subscribe_and_join(GameChannel, "games:lobby", %{})

    assert_push "start", %{ color: "white", uuid: "socket_id_1"}
    assert_push "start", %{ color: "black", uuid: "socket_id_2"}
  end


  test "start game should remove the seek from redis", %{socket: socket} do
    {:ok, redis_client} = Exredis.start_link
    redis_client |> Exredis.query(["DEL", "seeks"])

    socket("socket_id_1", %{uuid: "socket_id_1"})
      |> subscribe_and_join(GameChannel, "games:lobby", %{})
    
    [ player_1 | _ ] = redis_client |> Exredis.query(["SMEMBERS", "seeks"])
    assert "socket_id_1" == player_1

    socket("socket_id_2", %{uuid: "socket_id_2"})
      |> subscribe_and_join(GameChannel, "games:lobby", %{})


    assert (redis_client |> Exredis.query(["EXISTS", "seeks"])) == "0"
  end

  # # test "shout broadcasts to test:lobby", %{socket: socket} do
  #   push socket, "shout", %{"hello" => "all"}
  #   assert_broadcast "shout", %{"hello" => "all"}
  # end

  # test "broadcasts are pushed to the client", %{socket: socket} do
  #   broadcast_from! socket, "broadcast", %{"some" => "data"}
  #   assert_push "broadcast", %{"some" => "data"}
  # end
end
