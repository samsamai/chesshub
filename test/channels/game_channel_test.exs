defmodule HelloPhoenix.GameChannelTest do
  use HelloPhoenix.ChannelCase

  alias HelloPhoenix.GameChannel

  setup do
    {:ok, redis_client} = Exredis.start_link
    redis_client |> Exredis.query(["DEL", "seeks"])

    {:ok, _, socket} =
      socket("socket_id", %{})
      |> subscribe_and_join(GameChannel, "games:lobby", %{ uuid: "1234" })

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

    assert_broadcast "start", %{"color" => "white", "uuid" => _}
    assert_broadcast "start", %{"color" => "black", "uuid" => _}
  end

  test "joining creates a seek in redis" do
    {:ok, redis_client} = Exredis.start_link
    [ player_1 | _ ] = redis_client |> Exredis.query(["SMEMBERS", "seeks"])
    assert "1234" == player_1
  end

  test "second join should set player_2 in redis" do
    uuid_player_1 = "1234"
    uuid_player_2 = "9876"
    {:ok, redis_client} = Exredis.start_link
    redis_client |> Exredis.query(["DEL", "seeks"])

    socket("socket_id2", %{})
      |> subscribe_and_join(GameChannel, "games:lobby", %{ uuid: uuid_player_1 })
    
    socket("socket_id2", %{})
      |> subscribe_and_join(GameChannel, "games:lobby", %{ uuid: uuid_player_2 })

    assert_broadcast "start", %{"color" => "white", "uuid" => "1234"}
    assert_broadcast "start", %{"color" => "black", "uuid" => "9876"}
  end

  test "start game should remove the seek from redis", %{socket: socket} do
    {:ok, redis_client} = Exredis.start_link
    redis_client |> Exredis.query(["DEL", "seeks"])
    redis_client |> Exredis.query(["SADD", "5555"])

    socket("socket_id2", %{})
      |> subscribe_and_join(GameChannel, "games:lobby", %{ uuid: "5555" })
    
    [ player_1 | _ ] = redis_client |> Exredis.query(["SMEMBERS", "seeks"])
    assert "5555" == player_1

    socket("socket_id2", %{})
      |> subscribe_and_join(GameChannel, "games:lobby", %{ uuid: "7777" })


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
