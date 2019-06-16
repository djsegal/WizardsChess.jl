module WizardsChess

  using Revise
  using Blink
  using Chess

  include("structs.jl")
  include("valid_moves.jl")

  characters = [
  "a", "b", "c", "d",
  "e", "f", "g", "h"
  ]

  algebraic_notation = function (row,col)
      characters[col] * string(row)
  end

  export start

  function build_board!(game)
    work_string = "";
    work_string *= "\$('.cs-overlay').removeClass('active');"
    work_string *= "\$('.cs-overlay').removeClass('cs-capture');"
    work_string *= "\$('.cs-overlay').removeClass('cs-castle');"
    work_string *= "\$('#js-table .svg-inline--fa').remove();"

    for i in 1:8
      for j in 1:8
        isnothing(game.board[i,j]) && continue

        piece = game.board[i,j]
        piece_name = lowercase(last(split(string(typeof(piece)),".")))
        piece_color = piece.player.is_white ? "white" : "black"

        work_string *= """
          \$("#js-row__$(i) #js-col__$(j)").prepend('<i class="fas fa-chess-$(piece_name) cs-$(piece_color)"></i>');
        """
      end
    end

    for player in game.players
      isnothing(player.anti_pawn) && continue
      piece_color = player.is_white ? "white" : "black"

      work_string *= """
        \$("#js-row__$(player.anti_pawn.row) #js-col__$(player.anti_pawn.col)").prepend('<i class="fas fa-circle cs-$(piece_color)"></i>');
      """
    end

    cur_string = Blink.JSString(work_string)
    @js_(game.window, $cur_string)
  end

  function fen(game::Game)
    fen = ""

    string_array = []
    for row in 8:-1:1
      push!(string_array, "")
      white_space = 0
      for col in 1:8
        tmp_piece = game.board[row,col]

        if isnothing(tmp_piece)
          white_space += 1
          continue
        end

        if white_space > 0
          string_array[end] *= string(white_space)
          white_space = 0
        end

        tmp_piece_name = lowercase(last(split(string(typeof(tmp_piece)),".")))
        piece_char = tmp_piece_name == "knight" ? "n" : tmp_piece_name[1]
        piece_char = ( tmp_piece.player.is_white ) ? uppercase(piece_char) : lowercase(piece_char)

        string_array[end] *= piece_char
      end
      ( white_space > 0 ) && ( string_array[end] *= string(white_space) )
    end

    fen *= join(string_array, "/")

    fen *= game.is_whites_turn ? " w" : " b"

    white = filter(player -> player.is_white, game.players)[1]
    black = filter(player -> !player.is_white, game.players)[1]

    castling_string = ""

    white.can_castle_right && ( castling_string *= "K" )
    white.can_castle_left && ( castling_string *= "Q" )
    black.can_castle_right && ( castling_string *= "k" )
    black.can_castle_left && ( castling_string *= "q" )

    ( castling_string == "" ) && ( castling_string = "-" )

    fen *= " " * castling_string * " "

    if game.is_whites_turn
      fen *= isnothing(black.anti_pawn) ? "-" : algebraic_notation(black.anti_pawn.row,black.anti_pawn.col)
    else
      fen *= isnothing(white.anti_pawn) ? "-" : algebraic_notation(white.anti_pawn.row,white.anti_pawn.col)
    end

    fen *= " " * string(game.halfmove_clock)

    fen *= " " * string(game.fullmove_number)

    fen
  end

  function start()

    window = Window(async=false)
    size(window, (size(window)*1.5)...)

    js_pipeline = [
      ["core", "jquery.min.js"],
      ["core", "popper.min.js"],
      ["init.js"],
      ["bootstrap-material-design.js"],
      ["plugins", "moment.min.js"],
      ["plugins", "bootstrap-selectpicker.js"],
      ["plugins", "bootstrap-tagsinput.js"],
      ["plugins", "jasny-bootstrap.min.js"],
      ["plugins", "nouislider.min.js"],
      ["material-kit.js"],
      ["font-awesome.js"]
    ]

    for asset in js_pipeline
      load!(window, abspath(@__DIR__,"..", "assets", "js", asset...),async=false)
    end

    css_pipeline = [
      ["material-kit.css"]
    ]

    for asset in css_pipeline
      load!(window, abspath(@__DIR__,"..", "assets", "css", asset...),async=false)
    end

    loadcss!(window, "https://fonts.googleapis.com/css?family=Roboto:300,400,500,700|Roboto+Slab:400,700|Material+Icons")
    # loadjs!(window, "https://kit.fontawesome.com/fd1fd9f86d.js")

    load!(window, abspath(@__DIR__,"..", "assets", "app.css"), async=false)
    body!(window, String(read(abspath(@__DIR__,"..", "assets", "app.html"))), async=false)
    load!(window, abspath(@__DIR__,"..", "assets", "app.js"), async=false)

    game = Game(window)

    build_board!(game)

    println(fen(game))

    handle(window, "click_piece") do args
      row, col = map(arg -> parse(Int,arg),args)
      piece = game.board[row,col]

      # ( piece.player.is_white == game.is_whites_turn ) || return

      moves = valid_moves(piece)

      work_string = """
        var thisIsWhite = \$("#js-row__$(row) #js-col__$(col) .svg-inline--fa").hasClass("cs-white");
        var thatIsWhite = false;
        var usedClass = "";
      """

      work_string *= "\$('.cs-overlay').removeClass('active');"
      work_string *= "\$('.cs-overlay').removeClass('cs-capture');"
      work_string *= "\$('.cs-overlay').removeClass('cs-castle');"

      for (i,j) in moves
        work_string *= """
          \$("#js-row__$(i) #js-col__$(j) .cs-overlay").addClass('active');

          thatIsWhite = \$("#js-row__$(i) #js-col__$(j) .svg-inline--fa").hasClass("cs-white");

          if ( thisIsWhite == thatIsWhite ) {
            usedClass = 'cs-castle';
          } else {
            usedClass = 'cs-capture';
          }

          if ( \$("#js-row__$(i) #js-col__$(j) .svg-inline--fa").length > 0 ) {
            \$("#js-row__$(i) #js-col__$(j) .cs-overlay").addClass(usedClass);
          }
        """
      end

      cur_string = Blink.JSString(work_string)
      @js_(window, $cur_string)
    end

    handle(window, "click_overlay") do args
      game.halfmove_clock += 1

      piece_row, piece_col, overlay_row, overlay_col = map(arg -> parse(Int,arg),args)
      piece = game.board[piece_row,piece_col]

      # @assert piece.player.is_white == game.is_whites_turn

      moves = valid_moves(piece)
      @assert [overlay_row,overlay_col] in moves

      piece.row = overlay_row
      piece.col = overlay_col

      piece.player.anti_pawn = nothing
      game.board[piece_row,piece_col] = nothing

      piece_name = lowercase(last(split(string(typeof(piece)),".")))
      other_piece = game.board[overlay_row,overlay_col]
      if isnothing(other_piece)
        game.board[overlay_row,overlay_col] = piece
      else
        other_piece_name = lowercase(last(split(string(typeof(other_piece)),".")))
        if piece.player == other_piece.player
          @assert piece_name == "rook"
          @assert other_piece_name == "king"
          @assert piece_col == 1 || piece_col == 8

          game.board[piece.row,piece.col] = nothing
          game.board[other_piece.row,other_piece.col] = nothing

          if piece_col == 1
            @assert piece.player.can_castle_left
            other_piece.col = 3
            piece.col = 4
          elseif piece_col == 8
            @assert piece.player.can_castle_right
            other_piece.col = 7
            piece.col = 6
          end

          game.board[piece.row,piece.col] = piece
          game.board[other_piece.row,other_piece.col] = other_piece

          piece.player.has_castled = true
          piece.player.can_castle_left = false
          piece.player.can_castle_right = false
        else
          filter!(tmp_piece -> tmp_piece != other_piece, other_piece.player.pieces)
          game.board[overlay_row,overlay_col] = piece
          ( piece_name == "pawn" ) || ( game.halfmove_clock -= 1 )
        end
      end

      if piece_name == "pawn"
        game.halfmove_clock -= 1
        if piece.row == 1 || piece.row == 8
          cur_string = Blink.JSString("\$('#exampleModal').modal({show: true})")
          @js_(game.window, $cur_string)
        end

        is_white = piece.player.is_white

        is_init = (
          ( is_white && piece_row == 2 ) ||
          ( !is_white && piece_row == 7 )
        )

        if is_init && abs(piece_row - overlay_row) > 1
          @assert piece_col == overlay_col
          @assert abs(piece_row - overlay_row) == 2
          piece.player.anti_pawn = AntiPawn(
            piece.player, Int((piece_row+overlay_row)/2), piece.col
          )
        end

        other_player = filter(tmp_player -> tmp_player != piece.player, game.players)[1]

        anti_pawn = other_player.anti_pawn
        if !isnothing(anti_pawn) && piece.row == anti_pawn.row && piece.col == anti_pawn.col
          if piece.player.is_white
            @assert piece.row == 6
            captured_pawn = game.board[piece_row,piece.col]
            @assert !isnothing(captured_pawn)

            captured_pawn_name = lowercase(last(split(string(typeof(captured_pawn)),".")))
            @assert captured_pawn_name == "pawn"
            @assert captured_pawn.player == other_player

            game.board[captured_pawn.row,captured_pawn.col] = nothing
            filter!(tmp_piece -> tmp_piece != captured_pawn_name, other_player.pieces)
          else
            @assert piece.row == 3
          end
        end
      end

      if piece_name == "king"
        piece.player.can_castle_left = false
        piece.player.can_castle_right = false
      end

      if piece_name == "rook"
        if piece.player.can_castle_left && piece_col == 1
          piece.player.can_castle_left = false
        elseif piece.player.can_castle_right && piece_col == 8
          piece.player.can_castle_right = false
        end
      end

      if piece.player.is_white
        game.is_whites_turn = false

        black = filter(player -> !player.is_white, game.players)[1]
        black.anti_pawn = nothing
      else
        game.fullmove_number += 1
        game.is_whites_turn = true

        white = filter(player -> player.is_white, game.players)[1]
        white.anti_pawn = nothing
      end

      println(fen(game))

      build_board!(game)
    end

    handle(window, "select_piece") do args
      pawns = filter(piece -> isa(piece,Pawn), vcat(map(player -> player.pieces, game.players)...))

      filter!(pawn -> ( pawn.row == 1 || pawn.row == 8 ), pawns)
      @assert length(pawns) == 1

      @assert length(args) == 1
      piece_class = getfield(WizardsChess, Symbol(args[1]))

      pawn = pawns[1]

      filter!(tmp_piece -> tmp_piece != pawn, pawn.player.pieces)

      piece = piece_class(pawn.player, pawn.row, pawn.col)
      push!(pawn.player.pieces, piece)

      game.board[pawn.row,pawn.col] = piece
      build_board!(game)

      cur_string = Blink.JSString("\$('#exampleModal').modal('hide')")
      @js_(game.window, $cur_string)
    end

    handle(window, "new_game") do args
      game = Game(window)

      build_board!(game)
    end

    game

  end

end
