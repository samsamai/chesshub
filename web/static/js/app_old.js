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
import "phoenix_html"

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
    this.chess = Chess();
    let messagesContainer = $( '#messages' );
    let uuid = Math.floor(Math.random() * (1024));

    let channel = socket.channel("games:lobby", {uuid: uuid})
    channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })


    channel.on("make_move", payload => {
      console.log( "channel.on make_move" );
      messagesContainer.append(`<br/> ${payload.color}`)
    })

    let cfg = {
      draggable: true,
      pieceTheme: "images/chesspieces/alpha/{piece}.png",
      showNotation: true,


      onDragStart: (source, piece, position, orientation) => {
      /*make sure the player is allowed to pick up the piece*/
      console.log( "DragStart" );
        // return !(this.chess.game_over() ||
        //          (this.chess.turn() == "w" && piece.search(/^b/) != -1) ||
        //          (this.chess.turn() == "b" && piece.search(/^w/) != -1) ||
        //          (orientation == "white" && piece.search(/^b/) != -1) ||
        //          (orientation == "black" && piece.search(/^w/) != -1))
        return true;
      },

      onDrop: (source, target) => {
        console.log( "onDrop" );
        console.log( `from: ${source}` );
        console.log( `to: ${target}` );

        // let channel = socket.channel("games:lobby", {});

        let move = this.chess.move( {from: source, to: target, promotion: "q"} );

        console.log( `move: ${move}` );

        if (move == null) {
           // illegal move 
           console.log( "illegal move" );
           return "snapback";
         }
         else {
           console.log( "performing move" );
           // this.chess.game("make_move", move);
           // if (this.channel) {
            console.log( "pushing to console" );

            //channel.push("make_move", move);
          // }
        }
      }
    };

    this.board = ChessBoard("chessboard", cfg);
  }
};

console.log( "pre init" );
$( () => {
    App.init();
    App.board.position( "start" );
    App.board.orientation( "black" );
  }
);

export default App;

