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
  @WHITE_SQUARE_COLOR = "rgb(240,218,176)"
  @BLACK_SQUARE_COLOR = "rgb(180,137,92)"
  @SIZE = 500

  @xScale: d3.scale.linear()
    .domain([0, 8])
    .rangeRound([0, BoardView.SIZE - 1])

  @yScale: d3.scale.linear()
    .domain([0, 8])
    .rangeRound([BoardView.SIZE - (BoardView.SIZE / 8), - (BoardView.SIZE / 8)])

  @xReverseScale: d3.scale.linear()
    .domain([0, BoardView.SIZE])
    .rangeRound([0, 8])

  @yReverseScale: d3.scale.linear()
    .domain([BoardView.SIZE - (BoardView.SIZE / 8), - (BoardView.SIZE / 8)])
    .rangeRound([0, 8])

  constructor: (@board, @parent, @size) ->
    @svg = d3.select(@parent).append("svg:svg")
      .attr("width", @size)
      .attr("height", @size)
    @draw_board()

  update: () ->
    pieces =  @svg.selectAll(".piece")
      .data(@board.model.pieces, (piece) -> return piece.id)

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
    for i in [0..7]
      for j in [0..7]
        color = if (i + j) % 2 == 0 then BoardView.BLACK_SQUARE_COLOR else BoardView.WHITE_SQUARE_COLOR
        @svg.append("svg:rect")
          .attr("x", BoardView.xScale(i))
          .attr("y", BoardView.yScale(j))
          .attr("width", @size/8)
          .attr("height", @size/8)
          .attr("fill", color)

  draw_board: () ->
    @draw_grid()

    view = this
    board = @board

    drag = d3.behavior.drag()
      .origin( (d) ->
        pos = board.position_of(d)
        return {
          x: pos[0]
          y: pos[1]
        }
      )
      .on "dragstart", (d) ->
        # TODO: This causes pieces to flicker when they're dragged.
        $svg = $(view.svg[0])
        $svg.append(d3.select this)  # Move node to end so it's top layer.
      .on "drag", (d) ->
        if board.position_of(d) is null
          return
        curX = parseInt(d3.select(this).attr("x"))
        curY = parseInt(d3.select(this).attr("y"))
        d3.select(this)
          .attr("x", curX += d3.event.dx)
          .attr("y", curY += d3.event.dy)
    drag.on "dragend", (d) ->
      elem = d3.select(this)
      x = parseFloat(elem.attr("x"))
      y = parseFloat(elem.attr("y"))
      new_pos = [BoardView.xReverseScale(x), BoardView.yReverseScale(y)]
      board.move(board.position_of(d), new_pos)

      view.update()

    pieces =  @svg.selectAll(".piece")
      .data(@board.model.pieces, (piece) -> return piece.id)
    pieces
     .enter()
     .append("svg:image")
     .attr("xlink:href", (piece) ->
       "assets/" + piece.color + "-" + piece.type + ".svg")
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
     .call(drag)


class BoardModel
  constructor: () ->
    @board = []
    @pieces = []
    @captured_blacks = []
    @captured_whites = []
    @history = []
    @board.push([null, null, null, null, null, null, null, null]) for i in [1..8]


class Board
  constructor: (@model) ->
    @model ||= new BoardModel
    @setup()

  add_piece: (piece, pos) ->
    @model.pieces.push(piece)
    @model.board[pos[0]][pos[1]] = piece

  setup: () ->
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
    if pos[0] < 0 or pos[0] >= 8 or pos[1] < 0 or pos[1] >= 8
      return undefined
    return @model.board[pos[0]][pos[1]]

  position_of: (piece) ->
    for i in [0..7]
      for j in [0..7]
        if @model.board[i][j] and @model.board[i][j] is piece
          return [i, j]

    return null

  move: (start_pos, end_pos) ->
    if (start_pos[0] != end_pos[0] || start_pos[1] != end_pos[1]) && @is_legal(start_pos, end_pos)
      @capture(end_pos)
      piece = @at(start_pos)
      @model.board[start_pos[0]][start_pos[1]] = null
      @model.board[end_pos[0]][end_pos[1]] = piece
    @view.update()

  path_is_empty: (path) ->
    for pos in path
      if @at(pos) != null
        return false
    return true

  legal_moves_for: (pos) ->
    piece = @at(pos)
    possible = []
    if piece.type == "rook" or piece.type == "bishop" or piece.type == "queen"
      switch piece.type
        when "rook"
          deltas =  [ [-1, 0], [1, 0], [0, 1], [0, -1] ]
        when "bishop"
          deltas =  [ [-1, -1], [-1, 1], [1, -1], [1, 1] ]
        when "queen"
          deltas = [ [-1, 0], [1, 0], [0, 1], [0, -1], [-1, -1], [-1, 1], [1, -1], [1, 1] ]
      for delta in deltas
        dx = delta[0]
        dy = delta[1]
        cur_pos = [pos[0] + dx, pos[1] + dy]
        while @at(cur_pos) is null
          possible.push(cur_pos)
          cur_pos = [cur_pos[0] + dx, cur_pos[1] + dy]
        if @at(cur_pos)? and @at(cur_pos).color != piece.color
          possible.push(cur_pos)
      return possible

    if piece.type is "knight"
        moves = [ [1,2], [-1,2], [1, -2], [-1, -2], [2, 1], [-2, 1], [2, -1], [-2, -1]]
    if piece.type is "king"
        moves = [ [-1,-1], [-1, 0], [-1, 1], [0, -1], [0, 1], [1, -1], [1, 0], [1,1] ]
    if piece.type is "king" or piece.type is "knight"
      for move in moves
        new_pos = [pos[0] + move[0], pos[1] + move[1]]
        if @at(new_pos) is null or (@at(new_pos)? and @at(new_pos).color != @at(pos).color)
          possible.push(new_pos)
      return possible

    # If it's a pawn...
    attack_dir = if piece.color == "white" then 1 else -1
    if @at([pos[0], pos[1] + attack_dir]) is null
      possible.push([pos[0], pos[1] + attack_dir])
    attackable_positions = [ [pos[0] - 1, pos[1] + attack_dir], [pos[0] + 1, pos[1] + attack_dir] ]
    for attackable in attackable_positions
      if @at(attackable)? and @at(attackable).color != piece.color
        possible.push(attackable)

    return possible


  is_legal: (start_pos, end_pos) ->
    for legal_end_pos in @legal_moves_for(start_pos)
      if end_pos[0] == legal_end_pos[0] and end_pos[1] == legal_end_pos[1]
        return true

    return false

  capture: (pos) ->
    piece = @at(pos)
    if piece?
      @model.pieces.splice(@model.pieces.indexOf(piece), 1);
      if piece.color == "white"
        @model.captured_whites.push(piece)
      else
        @model.captured_blacks.push(piece)
    @model.board[pos[0]][pos[1]] = null
    return piece


@board = new Board
board_view = new BoardView(board, "#chess", 500)
@board.view = board_view


