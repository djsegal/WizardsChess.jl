valid_moves(piece::Bishop) = _valid_moves_diagonal(piece)

valid_moves(piece::Queen) = vcat(
  _valid_moves_straight(piece), _valid_moves_diagonal(piece)
)

function valid_moves(piece::Pawn)
  is_white = piece.player.is_white
  other_player = filter(tmp_player -> tmp_player != piece.player, piece.player.game.players)[1]

  if is_white
    @assert piece.row > 1
    direction = +1
  else
    @assert piece.row < 8
    direction = -1
  end

  @assert 1 <= piece.row+direction <= 8

  board = piece.player.game.board
  moves = []

  work_i, work_j = piece.row+direction, piece.col
  if isnothing(piece.player.game.board[work_i,work_j])
    push!(moves, [work_i, work_j])

    is_init = (
      ( is_white && piece.row == 2 ) ||
      ( !is_white && piece.row == 7 )
    )

    if is_init
      work_i, work_j = piece.row+2*direction, piece.col
      isnothing(piece.player.game.board[work_i,work_j]) && push!(moves, [work_i, work_j])
    end
  end

  work_i = piece.row+direction
  for work_j in piece.col .+ [-1,+1]
    ( 1 <= work_j <= 8 ) || continue

    anti_pawn = other_player.anti_pawn
    work_piece = board[work_i,work_j]

    can_move = !isnothing(anti_pawn) && anti_pawn.row == work_i && anti_pawn.col == work_j
    can_move |= !isnothing(work_piece) && work_piece.player != piece.player

    can_move && push!(moves, [work_i, work_j])
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
