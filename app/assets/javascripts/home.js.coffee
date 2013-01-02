# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

@piece = (color, type) ->
  return {
    id: Math.uuid()
    type: type
    color: color
  }

@pos = (position) ->
  if typeof(position) != "string"
    return position

  columns = "abcdefgh"
  column = columns.indexOf(position[0].toLowerCase())
  row = parseInt(position[1]) - 1
  if !(row >= 0 and row < 8 and column >= 0 and column < 8)
    console.error("Invalid location " + str)
  return [column, row]

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
        position = board.position_of(piece)
        return BoardView.xScale(position[0])
      )
      .attr("y", (piece) ->
        position = board.position_of(piece)
        return BoardView.yScale(position[1])
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
       position = board.position_of(piece)
       return BoardView.xScale(position[0])
     )
     .attr("y", (piece) ->
       position = board.position_of(piece)
       return BoardView.yScale(position[1])
     )
     .attr("class", "piece")
     .attr("width", @size/8)
     .attr("height", @size/8)



class Board
  constructor: (board_data) ->
    @board = board_data
    if !@board?
      this.setup()

  reset: () ->
    @board = []
    @pieces = []
    @captured_blacks = []
    @captured_whites = []
    @board.push([null, null, null, null, null, null, null, null]) for i in [1..8]

  add_piece: (piece, position) ->
    position = pos(position)

    @pieces.push(piece)
    @board[position[0]][position[1]] = piece

  setup: () ->
    this.reset()

    this.add_piece(piece("white", "rook"), pos "a1")
    this.add_piece(piece("white", "knight"), pos "b1")
    this.add_piece(piece("white", "bishop"), pos "c1")
    this.add_piece(piece("white", "queen"), pos "d1")
    this.add_piece(piece("white", "king"), pos "e1")
    this.add_piece(piece("white", "bishop"), pos "f1")
    this.add_piece(piece("white", "knight"), pos "g1")
    this.add_piece(piece("white", "rook"), pos "h1")

    this.add_piece(piece("black", "rook"), pos "a8")
    this.add_piece(piece("black", "knight"), pos "b8")
    this.add_piece(piece("black", "bishop"), pos "c8")
    this.add_piece(piece("black", "queen"), pos "d8")
    this.add_piece(piece("black", "king"), pos "e8")
    this.add_piece(piece("black", "bishop"), pos "f8")
    this.add_piece(piece("black", "knight"), pos "g8")
    this.add_piece(piece("black", "rook"), pos "h8")

    columns = "abcdefgh"
    for i in [0..7]
      this.add_piece(piece("white", "pawn"), pos("" + columns[i] + "2"))
      this.add_piece(piece("black", "pawn"), pos("" + columns[i] + "7"))

  at: (position) ->
    position = pos(position)
    return @board[position[0]][position[1]]

  position_of: (piece) ->
    for i in [0..7]
      for j in [0..7]
        if @board[i][j] and @board[i][j] is piece
          return [i, j]

  move: (start_pos, end_pos) ->
    start_pos = pos(start_pos)
    end_pos = pos(end_pos)

    @capture(end_pos)
    piece = @at(start_pos)
    @board[start_pos[0]][start_pos[1]] = null
    @board[end_pos[0]][end_pos[1]] = piece

  capture: (position) ->
    position = pos(position)
    piece = @at(position)
    if piece?
      @pieces.splice(@pieces.indexOf(piece), 1);
      if piece.color == "white"
        @captured_whites.push(piece)
      else
        @captured_blacks.push(piece)
    @board[position[0]][position[1]] = null
    return piece


@board = new Board
@board_view = new BoardView(board, "#chess", 500)

