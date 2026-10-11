// Original manufactured geometry. The table contains no identity labels.
module.exports=function({part,beam,ring,item,num,col,bool,token}){
 const metal=1088,coat=272,glass=1568,neon=288;
 const ink=[20,29,35],shell=[42,54,61],steel=[96,111,119],white=[222,216,195],cyan=[100,195,203],amber=[199,154,91],brass=[130,104,72];
 const rotY=a=>[Math.cos(a),0,Math.sin(a),0,1,0,-Math.sin(a),0,Math.cos(a)];
 const wedge=(name,size,pos,color,rotation)=>part(name,size,pos,color,metal,'','',rotation).replace('class="Part"','class="WedgePart"');
 const lamp=(name,size,pos,color,brightness,range)=>part(name,size,pos,color,neon,'',item('PointLight','Practical',num('Brightness',brightness)+num('Range',range)+col('Color',color)+bool('Shadows',true)));
 let room='';
 room+=part('Foundation',[58,1,54],[0,-.5,0],[25,34,39],816);
 // Broad quiet panels and deeply recessed joints let the table carry detail.
 for(let x=-24;x<=24;x+=8)for(let z=-20;z<=20;z+=8)room+=part('Coated floor cassette',[7.96,.08,7.96],[x,.04,z],[37,47,52],coat);
 room+=part('Rear shell',[58,18,1],[0,9,-22],ink,coat);
 for(const side of [-1,1]){
  room+=part('Acoustic wall',[1,18,46],[side*29,9,0],[27,37,43],coat);
  room+=part('Rear armored wing',[14,12,.8],[side*17.5,6.8,-21.3],shell,metal);
  for(let j=0;j<4;j++)room+=part('Shadow joint',[.055,11,.06],[side*17.5-5+j*3.3,6.8,-20.87],ink,coat);
  room+=beam('Structural diagonal',[side*10.5,1,-20.7],[side*23,14,-20.7],.42,steel,metal);
  room+=part('Upper structural lip',[15,.32,.55],[side*17.5,13,-20.7],steel,metal);
  room+=part('Lower brass seam',[13,.07,.1],[side*17.5,2,-20.75],brass,metal);
  room+=lamp('Recessed warm practical',[.07,7,.08],[side*25,6.8,-20.3],[255,223,177],.4,12);
  for(const z of [-14,0,14]){
   room+=part('Side rib',[.65,14,1.1],[side*27.4,7,z],shell,metal);
   room+=beam('Ceiling brace',[side*27.4,14,z],[side*18,16,z],.6,steel,metal);
  }
 }
 room+=part('Command recess',[19,10.5,1.1],[0,8,-21],ink,coat);
 room+=part('Inactive smoked display',[16,5.8,.15],[0,9.3,-20.4],[28,46,52],glass,num('Transparency',.25));
 room+=part('Recess canopy',[19,.6,1.8],[0,13.4,-20.7],shell,metal);
 for(const side of [-1,1]){
  room+=part('Display frame',[.34,8.4,.4],[side*9.2,8.5,-20.2],steel,metal);
  room+=part('Display status',[.08,2,.05],[side*8.6,7.7,-20.15],cyan,neon);
 }
 // A physical three-fold motif, with restrained emission instead of wall text.
 for(let i=0;i<3;i++){
  let x=(i-1)*2.5;
  room+=beam('Core seal',[x-.8,8,-20.18],[x,10,-20.18],.065,i===1?cyan:steel,metal);
  room+=beam('Core seal',[x,10,-20.18],[x+.8,8,-20.18],.065,i===1?cyan:steel,metal);
  room+=beam('Core seal',[x+.8,8,-20.18],[x-.8,8,-20.18],.065,i===1?cyan:steel,metal);
 }
 // Suspended practical: dark housing, warm inner diffuser, soft table illumination.
 room+=ring('Suspended precision ring',9.8,14.8,shell,.28,48);
 room+=ring('Suspended diffuser',9.5,14.65,white,.08,48);
 for(const x of [-7,7])for(const z of [-7,7])room+=beam('Suspension rod',[x,14.8,z],[x,19,z],.075,steel,metal);
 for(const x of [-6,6])room+=lamp('Table task light',[.1,.1,.1],[x,13.8,0],[242,230,203],1.2,27);
 for(const side of [-1,1]){
  const x=side*17;
  room+=part('Instrument base',[7.6,.7,4.4],[x,.4,-8.2],ink,coat);
  room+=part('Instrument armor',[7,2.6,3.8],[x,2,-8.2],shell,metal);
  room+=wedge('Instrument bevel',[7.6,.55,1.5],[x,3.7,-6.85],steel,rotY(Math.PI));
  room+=part('Console inset',[6.4,.16,3],[x,3.52,-8.4],ink,coat);
  room+=part('Quiet monitor',[5.5,2.1,.15],[x,4.6,-9.4],[28,46,52],glass,num('Transparency',.15));
  for(let i=0;i<5;i++)room+=part('Console switch',[.45,.12,.3],[x-1.6+i*.8,3.72,-7.4],i===0?amber:steel,coat);
  room+=part('Console copper lip',[7,.06,.09],[x,3.75,-6.6],brass,metal);
  for(let j=0;j<5;j++)room+=part('Console vent',[4,.04,.03],[x,1.1+j*.28,-6.28],ink,coat);
  room+=part('Equipment column',[3,8,3],[side*25,4,-13],ink,coat);
  for(let j=0;j<4;j++)room+=part('Equipment module',[2.6,1.35,.25],[side*25,1.5+j*1.65,-11.4],shell,metal);
 }
 let table='';
 table+=part('Raised table dais',[20,.3,16],[0,.2,0],[52,63,68],metal);
 table+=part('Pedestal shadow',[11,1.2,8],[0,1,0],ink,coat);
 table+=part('Pedestal shell',[9.7,1.1,6.8],[0,1.65,0],shell,metal);
 for(const side of [-1,1]){
  table+=beam('Angled support',[side*5.2,.5,-3.5],[side*7,3.1,-4],.65,steel,metal);
  table+=beam('Angled support',[side*5.2,.5,3.5],[side*7,3.1,4],.65,steel,metal);
  table+=part('Pedestal groove',[.04,.55,4.8],[side*4.9,1.7,0],ink,coat);
 }
 table+=part('Table armor',[17.8,.62,12.8],[0,3.15,0],shell,metal);
 table+=part('Table upper shell',[17.2,.22,12.2],[0,3.57,0],steel,metal);
 for(const side of [-1,1]){
  table+=wedge('Beveled long edge',[17.8,.45,.7],[0,3.42,side*6.2],steel,rotY(side<0?0:Math.PI));
  table+=part('Side black inset',[.12,.22,10.4],[side*8.92,3.12,0],ink,coat);
  table+=part('Copper side trim',[.065,.055,9],[side*8.98,3.47,0],brass,metal);
 }
 table+=part('Recessed black gasket',[15.8,.08,10.8],[0,3.69,0],ink,coat);
 table+=part('Table glass',[15.5,.12,10.5],[0,3.77,0],[26,48,53],glass,num('Transparency',.24));
 table+=part('Projection substrate',[15.4,.02,10.4],[0,3.72,0],[23,41,47],coat);
 for(const z of [-5.8,5.8])table+=part('Edge inlay',[12,.025,.035],[0,3.7,z],cyan,neon);
 for(const x of [-8.5,8.5])table+=part('Edge inlay',[.03,.025,7],[x,3.7,0],cyan,neon);
 for(const x of [-8.2,8.2])for(const z of [-5.8,5.8]){
  table+=part('Corner housing',[.45,.15,.45],[x,3.65,z],ink,coat);
  table+=part('Emitter status',[.08,.025,.16],[x,3.75,z],amber,neon);
 }
 for(let i=-6;i<=6;i+=2)table+=part('Glass grid',[.012,.012,10],[i,3.85,0],[42,65,71],coat);
 for(let i=-4;i<=4;i+=2)table+=part('Glass grid',[15,.012,.012],[0,3.85,i],[42,65,71],coat);
 table+=ring('Axiom projection perimeter',3.65,4.05,[60,109,116],.025,48);
 table+=ring('Inner reticle',2.8,4.07,[46,76,81],.018,40);
 table+=ring('Projection crown',1.25,6.05,[78,151,158],.032,36);
 table+=ring('Projection base',.8,4.5,[78,151,158],.025,32);
 const corners=[[0,6.7,0],[-.9,5.55,0],[0,5.55,.9],[.9,5.55,0],[0,5.55,-.9],[0,4.45,0]];
 for(let i=1;i<=4;i++){
  table+=beam('Core lattice',corners[0],corners[i],.045,cyan);
  table+=beam('Core lattice',corners[5],corners[i],.035,cyan);
  table+=beam('Core equator',corners[i],corners[i===4?1:i+1],.025,cyan);
 }
 table+=part('Axiom nucleus',[.22,.22,.22],[0,5.55,0],white,neon);
 for(const side of [-1,1])for(let i=0;i<5;i++){
  const x=(i-2)*2.7,z=side*3.5,y=4.1,color=side<0?amber:cyan;
  table+=ring('Unit contact',.52,y,color,.025,16,[x,z]);
  table+=part('Unit emitter',[.46,.12,.46],[x,y-.04,z],steel,metal);
  table+=part(`Unit hologram ${side<0?'B':'A'} ${i+1}`,[.2,.62,.2],[x,y+.4,z],color,neon,num('Transparency',.18));
 }
 for(let i=0;i<12;i++){
  const a=i*Math.PI/6;table+=beam('Calibration tick',[3.9*Math.cos(a),4.08,3.9*Math.sin(a)],[4.08*Math.cos(a),4.08,4.08*Math.sin(a)],.022,[68,93,96],metal);
 }
 for(let i=0;i<8;i++)table+=part('Cooling grille',[.055,.18,.05],[-2.8+i*.8,3.17,6.47],ink,coat);
 for(const x of [-7.5,7.5])for(const z of [-5.4,5.4])table+=part('Machined fastener',[.1,.02,.1],[x,3.7,z],steel,metal);
 room+=item('Model','StrategicTable','',table);
 room+=part('Front control pedestal',[1.2,2.6,1.2],[0,1.4,9],shell,metal);
 room+=wedge('Front control surface',[6,.65,2],[0,2.85,9],steel,rotY(Math.PI));
 room+=part('Front inactive touch surface',[5,.06,1.1],[0,3.23,8.7],ink,coat);
 // Four low, non-emissive floor traces establish scale without a noisy grid.
 for(const x of [-10,10])room+=part('Floor trace',[.045,.015,22],[x,.09,0],brass,metal);
 room+=lamp('Warm ambient rig',[.1,.1,.1],[-16,10,7],[255,214,174],.75,32);
 room+=lamp('Cool soft rig',[.1,.1,.1],[10,12,2],[201,224,233],1.25,38);
 room+=lamp('Rear separator',[.1,.1,.1],[0,10,-16],[132,174,183],.65,23);
 return room;
};
