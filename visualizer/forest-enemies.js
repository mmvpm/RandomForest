/* Editable forest enemy symbols and explicit lighting presets for mixed test levels. */
(function(root){
  const entries=[
    ['F','f','Корневая пасть','#88779a'],['J','j','Смоляной прыгун','#bb8a9b'],
    ['C','c','Коробейник спор','#a18baf'],['T','t','Вересковая мышь','#aa94c1'],
    ['G','g','Берестяной страж','#c69b78'],['W','w','Полый жнец','#9586a8'],
    ['1',null,'Страж · день','#b8926c'],['2',null,'Страж · вечер','#9e8197'],
    ['3',null,'Страж · ночь','#796c96'],['4',null,'Страж · утро','#c4b798'],
    ['5',null,'Прыгун · вечер','#b78594'],['6',null,'Прыгун · ночь','#8d81b8'],['7',null,'Прыгун · утро','#c6a077']
  ];
  const names={},rotated={},items=[],bySymbol={};
  for(const [right,left,label,color] of entries){
    names[right]=label+(left?' вправо':'');bySymbol[right]={label,color};
    if(left){names[left]=label+' влево';rotated[right]=left;rotated[left]=right;bySymbol[left]={label,color};}
    items.push({label,symbol:right,symbols:right+(left||''),color});
  }
  // Draws a compact labelled marker on the editor's semantic cell grid.
  function draw(context,symbol,x,y){
    const item=bySymbol[symbol];if(!item)return false;
    context.save();context.fillStyle=item.color;context.fillRect(x+2,y+2,12,12);
    context.fillStyle='#1c1829';context.font='bold 11px monospace';context.textAlign='center';context.textBaseline='middle';
    context.fillText(symbol.toUpperCase(),x+8,y+8);context.restore();return true;
  }
  const api={names,rotated,items,draw};root.ForestEnemies=api;
  if(typeof module!=='undefined')module.exports=api;
})(typeof window==='undefined'?globalThis:window);
