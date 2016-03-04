defmodule HelloPhoenix.GameChannelTest do
  use HelloPhoenix.ChannelCase
  use Phoenix.Socket
  import Exredis.Api

  alias HelloPhoenix.GameChannel

  setup do
    {:ok, redis_client} = Exredis.start_link

    redis_client |> Exredis.query(["DEL", "player_1"])
    redis_client |> Exredis.query(["DEL", "player_2"])

    {:ok, _, socket} =
      socket("socket_id", %{})
      |> subscribe_and_join(GameChannel, "games:lobby", %{ uuid: 1234 })

    {:ok, socket: socket}
  end

  test "make_move broadcasts to games:lobby", %{socket: socket} do
    payload = %{"color" => "white", "flags" => "flags", "from" => "d2", "piece" => "p", "san" => "san", "to" => "d4"}
    ref = push socket, "make_move", payload
    assert_broadcast "make_move", payload
  end

  test "make_move broadcasts are pushed to the client", %{socket: socket} do
    payload = %{"color" => "white", "from" => "d2", "piece" => "p", "san" => "san", "to" => "d4"}

    broadcast_from! socket, "make_move", payload
    assert_push "make_move", payload
  end

  test "start_game should broadcast start for each uuid", %{socket: socket} do
    uuid_player_1 = 1234
    uuid_player_2 = 9876

    socket = assign( socket, :player_1, uuid_player_1 )
    socket = assign( socket, :player_2, uuid_player_2 )
    send(socket.channel_pid, :start_game)

    assert_broadcast "start", %{"color" => "white", "uuid" => uuid_player_1}
    assert_broadcast "start", %{"color" => "black", "uuid" => uuid_player_2}
  end

  test "join an empty lobby should set player_1 in redis", %{socket: socket} do
    {:ok, redis_client} = Exredis.start_link
    player_1 = redis_client |> Exredis.query(["GET", "player_1"])
    assert 1234 == String.to_integer( player_1 )

    # ref = push socket, "join", "games:lobby", %{ message: "9876" }
    # join( socket, "games:lobby", %{ message: 9876 })

    # {:ok, _, socket2} =
    #   socket("socket_2", %{})
    #   |> subscribe_and_join(GameChannel, "games:lobby", %{ uuid: 9876 })

    # assert 9876 == socket2.assigns[:player_2], "player_2 assign incorrect"
  end

  test "second join should set player_2 in redis" do
    IO.puts "second join should set player_2 in redis"
    {:ok, redis_client} = Exredis.start_link
    redis_client |> Exredis.query(["DEL", "player_1"])
    redis_client |> Exredis.query(["DEL", "player_2"])

    {:ok, _, socket2} =
      socket("socket_id2", %{})
      |> subscribe_and_join(GameChannel, "games:lobby", %{ uuid: 1234 })

    {:ok, _, socket2} =
      socket("socket_id2", %{})
      |> subscribe_and_join(GameChannel, "games:lobby", %{ uuid: 9876 })

    player_2 = redis_client |> Exredis.query(["GET", "player_2"])
    IO.puts "Player_2"
    IO.inspect player_2
    assert 9876 == String.to_integer( player_2 )

    # ref = push socket, "join", "games:lobby", %{ message: "9876" }
    # join( socket, "games:lobby", %{ message: 9876 })

    # assert 9876 == socket2.assigns[:player_2], "player_2 assign incorrect"
  end

  # test "shout broadcasts to test:lobby", %{socket: socket} do
  #   push socket, "shout", %{"hello" => "all"}
  #   assert_broadcast "shout", %{"hello" => "all"}
  # end

  # test "broadcasts are pushed to the client", %{socket: socket} do
  #   broadcast_from! socket, "broadcast", %{"some" => "data"}
  #   assert_push "broadcast", %{"some" => "data"}
  # end
end
