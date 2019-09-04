abstract type Piece end

abstract type AbstractPlayer end
abstract type AbstractGame end

mutable struct Pawn <: Piece
  player::AbstractPlayer
  row::Int
  col::Int
end

mutable struct AntiPawn <: Piece
  player::AbstractPlayer
  row::Int
  col::Int
end

mutable struct Bishop <: Piece
  player::AbstractPlayer
  row::Int
  col::Int
end

mutable struct Queen <: Piece
  player::AbstractPlayer
  row::Int
  col::Int
end

mutable struct Rook <: Piece
  player::AbstractPlayer
  row::Int
  col::Int
end

mutable struct King <: Piece
  player::AbstractPlayer
  row::Int
  col::Int
end

mutable struct Knight <: Piece
  player::AbstractPlayer
  row::Int
  col::Int
end

mutable struct Game <: AbstractGame
  window::Window
  players::Vector{AbstractPlayer}
  board::Matrix{Union{Nothing,Piece}}
  is_whites_turn::Bool
  history::Vector{AbstractString}
  halfmove_clock::Int
  fullmove_number::Int
end

mutable struct Player <: AbstractPlayer
  is_white::Bool
  pieces::Vector{Piece}
  game::AbstractGame
  can_castle_left::Bool
  can_castle_right::Bool
  has_castled::Bool
  anti_pawn::Union{Nothing,AntiPawn}
  is_human::Bool
end

function Player(is_white,game,is_human)
  Player(is_white,[],game,true,true,false,nothing,is_human)
end

function Game(window::Window; player_1_is_human=true, player_2_is_human=false)

  players = AbstractPlayer[]
  board = Matrix{Union{Nothing,Piece}}(nothing,8,8)

  game = Game(
    window,players,board,true,
    [], 0, 1
  )

  white = Player(true,game,player_1_is_human)
  black = Player(false,game,player_2_is_human)

  push!(game.players, white)
  push!(game.players, black)

  white_i = 2
  black_i = 7

  for j = 1:8
    push!(white.pieces, Pawn(white,white_i,j))
    push!(black.pieces, Pawn(black,black_i,j))
  end

  white_i = 1
  black_i = 8
  for j = [1,8]
    push!(white.pieces, Rook(white,white_i,j))
    push!(black.pieces, Rook(black,black_i,j))
  end

  white_i = 1
  black_i = 8
  for j = [2,7]
    push!(white.pieces, Knight(white,white_i,j))
    push!(black.pieces, Knight(black,black_i,j))
  end

  white_i = 1
  black_i = 8
  for j = [3,6]
    push!(white.pieces, Bishop(white,white_i,j))
    push!(black.pieces, Bishop(black,black_i,j))
  end

  j = 4
  push!(white.pieces, Queen(white,white_i,j))
  push!(black.pieces, Queen(black,black_i,j))

  j = 5
  push!(white.pieces, King(white,white_i,j))
  push!(black.pieces, King(black,black_i,j))

  for piece in [white.pieces..., black.pieces...]
    board[piece.row,piece.col] = piece
  end

  game

end
