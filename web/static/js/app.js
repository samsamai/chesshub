// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
// import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"

// $ ->
//  App.chess = new Chess()

// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html";

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import socket from "./socket"

class App {
 static init() {
  console.log( "init" );
  let messagesContainer = $( '#messages' );
  let uuid = Math.floor(Math.random() * (1024));

  let channel = socket.channel("games:lobby", {} )
  channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })


  channel.on("make_move", payload => {
    messagesContainer.append(`<br/>from: ${payload.from} to: ${payload.to}`)
    // this.chess.move( {from: "d2", to: "d4"} );
    this.board.move( `${payload.from}-${payload.to}` );
  })

  channel.on("start", payload => {
    console.log( "uuid: " + payload["uuid"] );
    console.log( "color: " + payload["color"] );

    this.chess = Chess();
    this.board = ChessBoard("chessboard", this.cfg);
    this.board.orientation( payload["color"] );
    this.board.position( "start" );
  })


  this.cfg = {
    draggable: true,
    pieceTheme: "images/chesspieces/alpha/{piece}.png",
    showNotation: true,

    onDragStart: (source, piece, position, orientation) => {
    /*make sure the player is allowed to pick up the piece*/
    console.log( "DragStart" );
      return !(this.chess.game_over() ||
               (this.chess.turn() == "w" && piece.search(/^b/) != -1) ||
               (this.chess.turn() == "b" && piece.search(/^w/) != -1) ||
               (orientation == "white" && piece.search(/^b/) != -1) ||
               (orientation == "black" && piece.search(/^w/) != -1))
    },

    onDrop: (source, target) => {
      console.log( "onDrop" );
      console.log( `from: ${source}` );
      console.log( `to: ${target}` );

      let move = this.chess.move( {from: source, to: target, promotion: "q"} );

      if (move == null) {
         // illegal move 
         console.log( "illegal move" );
         return "snapback";
       }
       else {
         console.log( "performing move" );
         // this.chess.game("make_move", move);
         // if (this.channel) {

          channel.push("make_move", move);
        // }
      }
    }
  };


  }
};

$( () => {
    App.init();
  }
);

export default App;

