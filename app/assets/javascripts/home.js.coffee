# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

@p = (pos) ->
  if typeof(pos) != "string"
    return pos
  columns = "abcdefgh"
  column = columns.indexOf(pos[0].toLowerCase())
  row = parseInt(pos[1]) - 1
  if !(row >= 0 and row < 8 and column >= 0 and column < 8)
    console.error("Invalid location " + str)
  return [column, row]


class Piece
  constructor: (@color, @type) ->
    @id = Math.uuid()


class BoardView
  @WHITE_SQUARE_COLOR = "#dddddd"
  @BLACK_SQUARE_COLOR = "#222222"
  @SIZE = 500

  @xScale: d3.scale.linear()
    .domain([0, 8])
    .rangeRound([0, BoardView.SIZE])

  @yScale: d3.scale.linear()
    .domain([0, 8])
    .rangeRound([BoardView.SIZE - (BoardView.SIZE / 8), - (BoardView.SIZE / 8)])

  constructor: (@board, @parent, @size) ->
    console.log(@size)
    @svg = d3.select(@parent).append("svg:svg")
      .attr("width", @size)
      .attr("height", @size)
    @draw_board()

  update: () ->
    pieces =  @svg.selectAll(".piece")
      .data(@board.pieces, (piece) -> return piece.id)

    pieces
      .exit()
      .style("opacity", 1)
      .transition()
      .style("opacity", 0)
      .remove()

    pieces
      .transition()
      .attr("x", (piece) ->
        pos = board.position_of(piece)
        return BoardView.xScale(pos[0])
      )
      .attr("y", (piece) ->
        pos = board.position_of(piece)
        return BoardView.yScale(pos[1])
      )

  draw_grid: () ->
    for i in [0..8]
      for j in [0..8]
        color = if (i + j) % 2 == 0 then BoardView.BLACK_SQUARE_COLOR else BoardView.WHITE_SQUARE_COLOR
        @svg.append("svg:rect")
          .attr("x", BoardView.xScale(i))
          .attr("y", BoardView.yScale(j))
          .attr("width", @size/8)
          .attr("height", @size/8)
          .attr("fill", color)

  draw_board: () ->
    @draw_grid()
    pieces =  @svg.selectAll(".piece")
      .data(@board.pieces, (piece) -> return piece.id)
    pieces
     .enter()
     .append("svg:image")
     .attr("xlink:xlink:href", (piece) ->
       "assets/" + piece.color + "-" + piece.type + ".png")
     .attr("x", (piece) ->
       pos = board.position_of(piece)
       return BoardView.xScale(pos[0])
     )
     .attr("y", (piece) ->
       pos = board.position_of(piece)
       return BoardView.yScale(pos[1])
     )
     .attr("class", "piece")
     .attr("width", @size/8)
     .attr("height", @size/8)



class Board
  constructor: (board_data) ->
    @board = board_data
    if !@board?
      @setup()

  reset: () ->
    @board = []
    @pieces = []
    @captured_blacks = []
    @captured_whites = []
    @board.push([null, null, null, null, null, null, null, null]) for i in [1..8]

  add_piece: (piece, pos) ->
    @pieces.push(piece)
    @board[pos[0]][pos[1]] = piece

  setup: () ->
    @reset()

    @add_piece(new Piece("white", "rook"), p "a1")
    @add_piece(new Piece("white", "knight"), p "b1")
    @add_piece(new Piece("white", "bishop"), p "c1")
    @add_piece(new Piece("white", "queen"), p "d1")
    @add_piece(new Piece("white", "king"), p "e1")
    @add_piece(new Piece("white", "bishop"), p "f1")
    @add_piece(new Piece("white", "knight"), p "g1")
    @add_piece(new Piece("white", "rook"), p "h1")

    @add_piece(new Piece("black", "rook"), p "a8")
    @add_piece(new Piece("black", "knight"), p "b8")
    @add_piece(new Piece("black", "bishop"), p "c8")
    @add_piece(new Piece("black", "queen"), p "d8")
    @add_piece(new Piece("black", "king"), p "e8")
    @add_piece(new Piece("black", "bishop"), p "f8")
    @add_piece(new Piece("black", "knight"), p "g8")
    @add_piece(new Piece("black", "rook"), p "h8")

    for i in [0..7]
      @add_piece(new Piece("white", "pawn"), [i, 1])
      @add_piece(new Piece("black", "pawn"), [i, 6])

  at: (pos) ->
    return @board[pos[0]][pos[1]]

  position_of: (piece) ->
    for i in [0..7]
      for j in [0..7]
        if @board[i][j] and @board[i][j] is piece
          return [i, j]

  move: (start_pos, end_pos) ->
    @capture(end_pos)
    piece = @at(start_pos)
    @board[start_pos[0]][start_pos[1]] = null
    @board[end_pos[0]][end_pos[1]] = piece

  capture: (pos) ->
    piece = @at(pos)
    if piece?
      @pieces.splice(@pieces.indexOf(piece), 1);
      if piece.color == "white"
        @captured_whites.push(piece)
      else
        @captured_blacks.push(piece)
    @board[pos[0]][pos[1]] = null
    return piece


@board = new Board
@board_view = new BoardView(board, "#chess", 500)

