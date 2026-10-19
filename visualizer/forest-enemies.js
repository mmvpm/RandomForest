/* Editable forest enemy families; the game selects artwork for the level's lighting. */
(function(root){
  const entries=[
    ['F','f','Корневая пасть','#88779a'],['J','j','Смоляной прыгун','#bb8a9b'],
    ['C','c','Коробейник спор','#a18baf'],['T','t','Вересковая мышь','#aa94c1'],
    ['G','g','Берестяной страж','#c69b78'],['W','w','Полый жнец','#9586a8']
  ];
  const names={},rotated={},items=[],bySymbol={};
  for(const [right,left,label,color] of entries){
    names[right]=label+(left?' вправо':'');bySymbol[right]={label,color};
    if(left){names[left]=label+' влево';rotated[right]=left;rotated[left]=right;bySymbol[left]={label,color};}
    items.push({label,symbol:right,symbols:right+(left||''),color});
  }
  // Fills one small silhouette in the icon's local 16×16 coordinate system.
  function polygon(context,color,points){
    context.fillStyle=color;context.beginPath();context.moveTo(...points[0]);
    for(const point of points.slice(1))context.lineTo(...point);
    context.closePath();context.fill();
  }

  // Draws the rooted jaw with leaves and a bright row of teeth.
  function drawMaw(context,color){
    polygon(context,'#68835d',[[1,14],[4,10],[7,12],[11,10],[15,14]]);
    context.fillStyle='#68835d';context.fillRect(6,8,3,5);
    polygon(context,color,[[2,3],[5,1],[13,2],[15,5],[10,6],[14,9],[11,11],[4,9]]);
    polygon(context,'#302938',[[5,4],[14,5],[9,7],[13,8],[6,8]]);
    context.fillStyle='#eee2bd';context.fillRect(7,4,2,2);context.fillRect(11,4,2,2);
    context.fillRect(8,7,2,2);
  }

  // Draws a resin drop with springy feet and a forward-looking eye.
  function drawHopper(context,color){
    polygon(context,color,[[2,12],[3,7],[7,2],[8,5],[11,4],[14,9],[13,13],[4,13]]);
    context.fillStyle='#715569';context.fillRect(2,13,4,2);context.fillRect(10,13,4,2);
    context.fillStyle='#e8c3bc';context.fillRect(5,7,2,3);
    context.fillStyle='#f5edcc';context.fillRect(10,8,3,2);
    context.fillStyle='#302938';context.fillRect(12,8,1,2);
  }

  // Draws the spore carrier as a banded barrel with a mushroom cap.
  function drawBomber(context,color){
    polygon(context,color,[[3,5],[12,5],[14,8],[13,13],[3,13],[2,8]]);
    context.fillStyle='#5d4e68';context.fillRect(3,6,10,2);context.fillRect(3,11,10,2);
    context.fillStyle='#d5c19a';context.fillRect(6,2,2,4);
    polygon(context,'#c5a1b2',[[2,3],[4,1],[9,1],[11,3],[11,4],[2,4]]);
    context.fillStyle='#eee2bd';context.fillRect(10,8,2,2);
    context.fillStyle='#5d4e68';context.fillRect(3,13,3,2);context.fillRect(10,13,3,2);
  }

  // Draws a bat with spread wings, pointed ears and a forward eye.
  function drawBat(context,color){
    polygon(context,color,[[1,4],[6,7],[10,7],[15,4],[14,11],[11,9],[9,13],
      [7,13],[5,9],[2,11]]);
    polygon(context,'#685774',[[6,9],[6,2],[8,4],[10,2],[11,9],[9,12],[7,12]]);
    context.fillStyle='#f4dab3';context.fillRect(9,6,2,2);
  }

  // Draws the bark guard's helmet, broad shield and planted feet.
  function drawGuard(context,color){
    context.fillStyle=color;context.fillRect(4,2,7,5);context.fillRect(3,7,9,6);
    context.fillStyle='#735a49';context.fillRect(4,13,3,2);context.fillRect(9,13,3,2);
    context.fillStyle='#ead4aa';context.fillRect(8,4,3,2);
    polygon(context,'#8b704f',[[2,7],[7,7],[8,11],[5,14],[2,12]]);
    context.fillStyle='#d7bb85';context.fillRect(4,8,1,4);
    context.fillStyle='#735a49';context.fillRect(12,7,2,5);
  }

  // Draws a hooded reaper with a tall curved scythe.
  function drawReaper(context,color){
    polygon(context,color,[[4,2],[7,1],[10,4],[9,8],[11,14],[3,14],[4,8],[2,5]]);
    polygon(context,'#39313f',[[5,4],[9,4],[9,7],[5,7]]);
    context.fillStyle='#e4d6b9';context.fillRect(7,5,2,1);
    context.fillStyle='#b69876';context.fillRect(12,3,1,12);
    polygon(context,'#d3ccc3',[[8,2],[10,1],[14,2],[15,5],[13,4],[10,3],[8,4]]);
  }

  const drawings={F:drawMaw,J:drawHopper,C:drawBomber,T:drawBat,G:drawGuard,W:drawReaper};

  // Places a mirrored mini icon in its map cell, using the same grid as legacy enemies.
  function draw(context,symbol,x,y,cellSize=16){
    const item=bySymbol[symbol];if(!item)return false;
    const mirrored=symbol!==symbol.toUpperCase();
    context.save();context.translate((x+(mirrored?1:0))*cellSize,y*cellSize);
    context.scale((mirrored?-1:1)*cellSize/16,cellSize/16);
    drawings[symbol.toUpperCase()](context,item.color);
    context.restore();return true;
  }
  const api={names,rotated,items,draw};root.ForestEnemies=api;
  if(typeof module!=='undefined')module.exports=api;
})(typeof window==='undefined'?globalThis:window);
