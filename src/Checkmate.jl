module Checkmate

  using Revise
  using Blink

  include("structs.jl")

  export start

  function valid_moves(piece::Pawn)
    is_white = piece.player.is_white

    if is_white
      @assert piece.row > 1
      direction = +1
    else
      @assert piece.row < 8
      direction = -1
    end

    board = piece.player.game.board
    moves = []

    work_i, work_j = piece.row+direction, piece.col
    isnothing(piece.player.game.board[work_i,work_j]) && push!(moves, [work_i, work_j])

    is_init = (
      ( is_white && piece.row == 2 ) ||
      ( !is_white && piece.row == 7 )
    )

    if is_init
      work_i, work_j = piece.row+2*direction, piece.col
      isnothing(piece.player.game.board[work_i,work_j]) && push!(moves, [work_i, work_j])
    end

    work_i = piece.row+direction
    for work_j in piece.col .+ [-1,+1]
      ( 1 <= work_j <= 8 ) || continue
      isnothing(piece.player.game.board[work_i,work_j]) && continue
      ( board[work_i,work_j].player == piece.player ) && continue
      push!(moves, [work_i, work_j])
    end

    moves
  end

  function _valid_moves_straight(piece::Piece)
    board = piece.player.game.board
    moves = []

    work_j = piece.col

    for work_i in piece.row-1:-1:1
      push!(moves, [work_i, work_j])
      isnothing(board[work_i,work_j]) && continue
      ( board[work_i,work_j].player == piece.player ) || break
      pop!(moves) ; break
    end

    for work_i in piece.row+1:+1:8
      push!(moves, [work_i, work_j])
      isnothing(board[work_i,work_j]) && continue
      ( board[work_i,work_j].player == piece.player ) || break
      pop!(moves) ; break
    end

    work_i = piece.row

    for work_j in piece.col-1:-1:1
      push!(moves, [work_i, work_j])
      isnothing(board[work_i,work_j]) && continue
      ( board[work_i,work_j].player == piece.player ) || break
      pop!(moves) ; break
    end

    for work_j in piece.col+1:+1:8
      push!(moves, [work_i, work_j])
      isnothing(board[work_i,work_j]) && continue
      ( board[work_i,work_j].player == piece.player ) || break
      pop!(moves) ; break
    end

    moves
  end

  function valid_moves(piece::Knight)
    board = piece.player.game.board
    moves = []

    for work_i in piece.row .+ [+1,-1]
      ( 1 <= work_i <= 8 ) || continue
      for work_j in piece.col .+ [+2,-2]
        ( 1 <= work_j <= 8 ) || continue
        is_valid = isnothing(piece.player.game.board[work_i,work_j])
        is_valid || ( is_valid = ( board[work_i,work_j].player != piece.player ) )
        is_valid && push!(moves, [work_i, work_j])
      end
    end

    for work_i in piece.row .+ [+2,-2]
      ( 1 <= work_i <= 8 ) || continue
      for work_j in piece.col .+ [+1,-1]
        ( 1 <= work_j <= 8 ) || continue
        is_valid = isnothing(piece.player.game.board[work_i,work_j])
        is_valid || ( is_valid = ( board[work_i,work_j].player != piece.player ) )
        is_valid && push!(moves, [work_i, work_j])
      end
    end

    moves
  end

  valid_moves(piece::Bishop) = _valid_moves_diagonal(piece)

  function valid_moves(piece::Rook)
    moves = _valid_moves_straight(piece)
    ( piece.player.can_castle_left || piece.player.can_castle_right ) || return moves
    piece.player.has_castled && return moves

    if piece.player.is_white
      work_i = 1
    else
      work_i = 8
    end

    king = piece.player.pieces[findfirst(work_piece -> isa(work_piece,King), piece.player.pieces)]

    ( piece.row == work_i ) || return moves
    ( king.row == work_i ) || return moves

    @assert king.col == 5

    if piece.col < king.col
      j_list = piece.col+1:king.col-1
    else
      j_list = king.col+1:piece.col-1
    end

    for work_j in j_list
      isnothing(piece.player.game.board[work_i,work_j]) || return moves
    end

    push!(moves, [king.row,king.col])

    moves
  end

  valid_moves(piece::Queen) = vcat(
    _valid_moves_straight(piece), _valid_moves_diagonal(piece)
  )

  function _valid_moves_diagonal(piece::Piece)
    board = piece.player.game.board
    moves = []

    for i_dir = [-1,+1]
      for j_dir = [-1,+1]
        work_i = piece.row + i_dir
        work_j = piece.col + j_dir

        while 1 <= work_i <= 8 && 1 <= work_j <= 8
          if isnothing(piece.player.game.board[work_i,work_j])
            push!(moves, [work_i, work_j])
          elseif board[work_i,work_j].player == piece.player
            break
          else
            push!(moves, [work_i, work_j])
            break
          end

          work_i += i_dir
          work_j += j_dir
        end
      end
    end

    moves
  end

  function valid_moves(piece::King)
    board = piece.player.game.board
    moves = []

    for work_i in piece.row .+ (-1:+1)
      ( 1 <= work_i <= 8 ) || continue
      for work_j in piece.col .+ (-1:+1)
        ( 1 <= work_j <= 8 ) || continue

        if !isnothing(piece.player.game.board[work_i,work_j]) && board[work_i,work_j].player == piece.player
          continue
        end

        push!(moves, [work_i, work_j])
      end
    end

    moves
  end

  function build_board!(game)
    work_string = "";
    work_string *= "\$('.cs-overlay').removeClass('active');"
    work_string *= "\$('.cs-overlay').removeClass('cs-capture');"
    work_string *= "\$('.cs-overlay').removeClass('cs-castle');"
    work_string *= "\$('.svg-inline--fa').remove();"

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

    cur_string = Blink.JSString(work_string)
    @js_(game.window, $cur_string)
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

    handle(window, "click_piece") do args
      row, col = map(arg -> parse(Int,arg),args)
      moves = valid_moves(game.board[row,col])

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
      piece_row, piece_col, overlay_row, overlay_col = map(arg -> parse(Int,arg),args)
      piece = game.board[piece_row,piece_col]

      moves = valid_moves(piece)
      @assert [overlay_row,overlay_col] in moves

      piece.row = overlay_row
      piece.col = overlay_col

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
        else
          filter!(tmp_piece -> tmp_piece != other_piece, other_piece.player.pieces)
          game.board[overlay_row,overlay_col] = piece
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

      build_board!(game)
    end

    game

  end

end
