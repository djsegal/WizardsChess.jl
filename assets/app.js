
$(document).on("click", ".svg-inline--fa", function(event) {
  var svg = event.target;

  if ( svg.nodeName !== "svg" ) {
    svg = svg.parentElement;
  }

  $(".svg-inline--fa").removeClass("active");
  $(svg).addClass("active");

  var td, tr;

  td = svg.parentElement;
  tr = td.parentElement;

  var trId, tdId;

  trId = tr.id.split("_").slice(-1)[0];
  tdId = td.id.split("_").slice(-1)[0];

  Blink.msg("click_piece", [trId, tdId]);
})

var chessLetters = ['?','A','B','C','D','E','F','G','H','!'];

$("#js-table").append("<tr id='js-top' class='bg-secondary text-light font-weight-bold'> </tr>");
for (var i = 8; i > 0; i--) {
  $("#js-table").append("<tr id='js-row__" + i + "'> </tr>");
}
$("#js-table").append("<tr id='js-bottom' class='bg-secondary text-light font-weight-bold'> </tr>");

$("#js-top").append("<td></td>");
$("#js-bottom").append("<td></td>");

for (var j = 1; j < 9; j++) {
  $("#js-top").append("<td> " + chessLetters[j] + "</td>");
  $("#js-bottom").append("<td> " + chessLetters[j] + "</td>");
}

$("#js-top").append("<td></td>");
$("#js-bottom").append("<td></td>");

for (var i = 8; i > 0; i--) {
  $("#js-row__" + i).append("<td class='bg-secondary text-light font-weight-bold'> " + i + "</td>");
  for (var j = 1; j < 9; j++) {
    $("#js-row__" + i).append("<td class='cs-tile' id='js-col__" + j + "'><div class='cs-overlay'></div></td>");
  }
  $("#js-row__" + i).append("<td class='bg-secondary text-light font-weight-bold'> " + i + "</td>");
}

$(document).on("click", ".cs-overlay.active", function(event) {
  var svg = $(".svg-inline--fa.active")[0];

  var td, tr;

  td = svg.parentElement;
  tr = td.parentElement;

  var pieceRow, pieceCol;

  pieceRow = tr.id.split("_").slice(-1)[0];
  pieceCol = td.id.split("_").slice(-1)[0];

  var overlay = event.target;

  var td, tr;

  td = overlay.parentElement;
  tr = td.parentElement;

  var trId, tdId;

  overlayRow = tr.id.split("_").slice(-1)[0];
  overlayCol = td.id.split("_").slice(-1)[0];

  if ( $(overlay).hasClass('cs-castle') ) {
    if( !confirm("Are you sure you want to castle?") ) {
      event.preventDefault();
      return;
    }
  }

  Blink.msg("click_overlay", [pieceRow, pieceCol, overlayRow, overlayCol]);
})
