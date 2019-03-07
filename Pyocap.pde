//Pyocap.pde
//中野キャンパス低層棟5階のペットボトルキャップ回収Boxの模倣
//by Utsuhology(Distorted_Unchi)
//「ペットボトルキャップ回収Box内部で物理エンジンで遊びたい」という欲求もあった


//>>>>>>>>>>>>>>>>>From USB memory<<<<<<<<<<<<<<<<<<//
//バックアップとしてDropbox,Desktop,USB memoryの三つに同じフォルダがあるので
//コピペで更新する際に間違えて古いものをコピペして死なないようにする警告文


//----簡易Readme----//
//○このプログラムはProcassing 3.1.1で組まれました。たぶん大丈夫だとは思うけど
//  違うバージョンだと動作しないかも
//○Fisica、Minimをインストールしてください。
//○Minimが頻繁に死ぬ
//○すべてマウス操作です。箱を拡大したときにものを追加するのは右クリック、
//  それ以外は左クリックでの操作になります。


//----ライブラリのインポートや定義----//

import fisica.*;
import ddf.minim.*;

FWorld world;

FPoly cap[]=new FPoly[100];
FBox bomb[]=new FBox[20];
FBox wall;

Minim minim;
AudioSnippet scaler;
AudioSnippet caper;
AudioSnippet recycler;
AudioSnippet bomber;
AudioSnippet bombon;
AudioSnippet bombgo;
AudioSnippet tooler;


//--------変数。//コメント [主な参照先]--------//

int bamen=0; //%2処理。%2=0:全体像,1:箱部分拡大 [全般]
int mode=0; //0:Cap 1:Bomb 2:Wall  [全般]
float SQ=20; //ボムの一辺の長さ&キャップの短いほうの辺の長さ（長いほうはその二倍） [全般]
float WL=8; //壁の一辺の長さ [全般]

int bcount=0; //画面内のボムの総数 [（関数）void PutABomb]
int ccount=0; //画面内のキャップの総数 [（関数）void PutACap、（関数）void AllClear]

int cRecycledSum=0; //回収されたキャップの総数 [（関数）void AllClear]

float bakhaTheta; //爆発処理でのキャップを飛ばす角度を入れる一時的な変数 [（関数）void StepBomb]
float bakhaVelocity; //爆発処理でのキャップを飛ばす角度を入れる一時的な変数 [（関数）void StepBomb]


//--Bombの諸々を決める変数群--//
float bx[]=new float[20]; //ボムのx座標取得用 [（関数）void StepBomb]
float by[]=new float[20]; //ボムのy座標取得用 [（関数）void StepBomb]
boolean bRed[]=new boolean[20]; //ボムが赤いか（着火状態であるか） [（関数）void StepBomb、void ContactStarted]
int bRedFrame[]=new int[20]; //ボムが赤くなってからの経過時間 [（関数）void StepBomb]
boolean bbombon[]=new boolean[20]; //着火音（bombon）が鳴ったか [（関数）void StepBomb、void ContactStarted]

boolean bLife[]=new boolean[20]; //ボムの生存。ボムが20個しか置けないように、このサイズ20の配列の真偽で管理する [（関数）void PutABomb]
//（ボムが消える処理があるのでAkinumやAkiExistanceを使った方法が必要。方法についてはvoid PutABomb参照）
int bAkinum; //bLife[]のうちで空いているものの番号を入れる [（関数）void PutABomb]
boolean bAkiExistance; //bLife[]のうち空いているものがあるか [（関数）void PutABomb]


//--Capの諸々を決める変数群--//
boolean cLife[]=new boolean[100]; //キャップの生存。キャップが100個しか置けないように、このサイズ20の配列の真偽で管理する [（関数）void PutACap]
//（こちらはキャップを消す必要がないのでAkinumやAkiExistanceを使わなくてよい）
float cx[]=new float[100]; //キャップのx座標取得 [（関数）void StepBomb]
float cy[]=new float[100]; //キャップのy座標取得 [（関数）void StepBomb]

//Wallについては変数を使わなかった。かなり簡単でびっくりした


//--------メイン処理くん--------//

void setup() {
  size(800, 500);
  smooth();

  //配列・変数の初期化

  for (int RP=0; RP<=19; RP++) {
    bLife[RP]=false;
    bRed[RP]=false;
    bbombon[RP]=false;
    bRedFrame[RP]=0;
    bx[RP]=0;
    by[RP]=0;
  }

  for (int RP=0; RP<=99; RP++) {
    cLife[RP]=false;
    cy[RP]=0;
    cy[RP]=0;
  }

  //Fisicaの初期化
  Fisica.init(this);
  world=new FWorld();
  world.setEdges(75, 0, 525, 300);
  Fisica.setScale(20);

  //Minimの初期化・読み込み
  minim=new Minim(this);

  scaler=minim.loadSnippet("scaler.wav");
  caper=minim.loadSnippet("caper.wav");
  recycler=minim.loadSnippet("recycler.wav");
  bomber=minim.loadSnippet("bomber.wav");
  bombon=minim.loadSnippet("bombon.wav");
  bombgo=minim.loadSnippet("bombgo.wav");
  tooler=minim.loadSnippet("tooler.wav");
}

void draw() {
  background(-1);
  //-----場面:全体像-----//
  if (bamen%2==0) {
    //ズームアウト
    ZoomoutScaler();
    //この場面ではすべてのものを掴めないようにする
    world.setGrabbable(false);
    //全体像の描画
    DrawWholeBox();
    //物の更新・描画（ボムのデータだけは別に処理する必要があった(StepBomb)）
    StepBomb();
    DrawMono();
    //ズームアウトおわり
    ZoomoutCuter();
    //ボタンやメニューウィンドウの描画
    DrawWholeSubs();
  }

  //-----場面:箱部分拡大-----//
  if (bamen%2==1) {
    //この場面では壁以外ものを掴めるようにする（壁はWallの追加のところで定義している）
    world.setGrabbable(true);
    //全体像の描画
    DrawWholeBox();
    //物の更新・描画（ボムのデータだけは別に処理する必要があった(StepBomb)）
    StepBomb();
    DrawMono();
    //ボタンやメニューウィンドウの描画
    DrawKakudaiSubs();
  }
}

//（補足、音について）関数にした動作に音をつけるとき、関数の内部に音を出す部分も入っている。

void mousePressed() {
  //-----場面:全体像-----//
  if (bamen%2==0) {
    //左クリック（＝ボタン操作）系
    if (mouseButton==LEFT) {
      if (dist(mouseX, mouseY, 200, 275)<12.5 && mouseButton==LEFT) {
        //穴内部でクリック:capの追加
        PutACap(random(75+75+SQ*2/2.0, 525-75-SQ*2/2.0), 0+SQ/2.0);
      }

      if (InRect(mouseX, mouseY, 0, 0, 50, 50)==true) {
        //拡大ボタンをクリック:場面転換
        bamen++;
        //拡大音（scaler）
        scaler.play(0);
      }
      if (InRect(mouseX, mouseY, 575, 450, 625, 500)==true) {
        //リサイクルボタンをクリック:リサイクル
        AllClear();
      }
    }
  }


  //-----場面:箱部分拡大-----//
  else if (bamen%2==1) { 
    //右クリック（＝追加）系
    if (mouseButton==RIGHT) {
      if (InRect(mouseX, mouseY, 75+SQ*2/2.0, 0+SQ/2.0, 525-SQ*2/2.0, 300-SQ/2.0)==true && mode==0) {
        //モードが0のとき枠内で右クリック:capの追加
        PutACap(mouseX, mouseY);
      }
      if (InRect(mouseX, mouseY, 75+SQ/2.0, 0+SQ/2.0, 525-SQ/2.0, 300-SQ/2.0)==true && mode==1) {
        //モードが1のとき枠内で右クリック:bombの追加
        PutABomb(mouseX, mouseY);
      }
    } 

    //左クリック（＝ボタン操作）系
    if (mouseButton==LEFT) {
      if (InRect(mouseX, mouseY, 110, 405, 190, 445)==true) {
        //Capボタンをクリック:capモード
        mode=0;
        //ツール選択音（tooler）
        tooler.play(0);
      }
      if (InRect(mouseX, mouseY, 260, 405, 340, 445)==true) {
        //Bombボタンをクリック:bombモード
        mode=1;
        //ツール選択音（tooler）
        tooler.play(0);
      }
      if (InRect(mouseX, mouseY, 410, 405, 490, 445)==true) {
        //Wallボタンをクリック:wallモード
        mode=2;
        //ツール選択音（tooler）
        tooler.play(0);
      }
      if (InRect(mouseX, mouseY, 0, 0, 50, 50)==true) {
        //拡大ボタンをクリック:場面転換
        bamen++;
        //拡大音（scaler）
        scaler.play(0);
      }
      if (InRect(mouseX, mouseY, 575, 450, 625, 500)==true) {
        //リサイクルボタンをクリック:リサイクル
        AllClear();
      }
    }
  }
}

void mouseDragged() {
  //-----場面:箱部分拡大-----//
  if (bamen%2==1) {
    if (mouseButton==RIGHT) {
      if (InRect(mouseX, mouseY, 75+SQ/4.0, 0+SQ/4.0, 525-SQ/4.0, 300-SQ/4.0)==true && mode==2) {
        //モードが2のとき枠内で右クリックでドラッグ:壁の描画
        PutAWall(mouseX, mouseY);
      }
    }
  }
}

////Fisicaの物体間で衝突が起こったときの処理（Fisica独自のメイン処理らしい）
//ボムが何かに触れたらbRed[]をtrueにしてそのボムを赤くする（着火する）
void contactStarted(FContact contacter) {
  //[ボムについての配列20サイズについてforで繰り返し
  for (int RP=0; RP<=19; RP++) {
    //空のFbody型変数bombBoxを用意
    FBody bombBox=null;
    //衝突した物体がbomb[RP]ならばbombBoxにbomb[RP]を代入
    if (contacter.getBody1()==bomb[RP]) {
      bombBox=contacter.getBody1();
    } else if (contacter.getBody2()==bomb[RP]) {
      bombBox=contacter.getBody2();
    }
    //（getBody1()とgetBody2()はそれぞれ衝突の際の一つ目の物体、二つ目の物体を取得できるので
    //こういった方式を取った）

    //bombBoxにbomb[RP]が入っているとき
    if (bombBox!=null) {
      //bRed[]をtrueにしてそのボムを赤くする（着火する）
      bRed[RP]=true;
      bombBox.setFill(255, 0, 0);
      //着火音（bombon）が鳴っていないなら鳴らす
      if (bbombon[RP]==false) {
        bombon.play(0);
        bbombon[RP]=true;
      }
    }
  }
  //繰り返しおわり]
}

void stop() {
  //Minimくんの終了しかしてない
  scaler.close();
  caper.close();
  recycler.close();
  bomber.close();
  bombon.close();
  bombgo.close();
  tooler.close();
  minim.stop();
  super.stop();
}


//-------------以下、整理のための関数----------------//

////キャップ回収ボックスの全体像を描画するだけの関数（寄っている状態）
//箱部分を拡大した全体像描画のこの状態が標準状態で、全体像が見える場面はscale(1/3.0)などを使って無理やり引いている
//（寄っている状態を標準状態にしないと、FisicaでものをDragさせるときに問題が生じる。）
void DrawWholeBox() {
  PFont FontMSG=createFont("MS-Gothic", 16);

  scale(3);
  translate(-100, -325);

  //-----黒の部分-----//
  //黒の輪郭
  stroke(0);
  strokeWeight(0.5);
  fill(50);
  rect(75, 25, 250, 450);
  rect(75, 475, 250, 50);

  //開けるねじ
  stroke(0);
  strokeWeight(0.5);
  fill(150);
  ellipse(100, 250, 15, 15);


  //-----ピンクの部分-----//
  //ピンクの輪郭
  stroke(0);
  strokeWeight(0.5);
  fill(#FCABF2); //ピンク
  rect(125, 50, 150, 275);

  //投入口
  stroke(0, 255, 0);
  strokeWeight(2);
  fill(-1);
  ellipse(200, 275, 35, 35);
  stroke(0);
  strokeWeight(0.5);
  fill(0);
  ellipse(200, 275, 25, 25);

  //「キャップ投入口」
  noStroke();
  fill(0, 230, 20);
  rect(170, 215, 60, 20);
  stroke(0, 230, 0);
  strokeWeight(1.2);
  noFill();
  rect(167.5, 212.5, 65, 25);

  noStroke();
  fill(0, 230, 20);
  rect(190, 235, 20, 5);
  triangle(185, 240, 215, 240, 200, 250);

  fill(-1);
  textFont(FontMSG);
  textAlign(CENTER);
  textSize(8);
  text("キャップ投入口", 200, 227.5);

  //「キャップの貯金箱」
  fill(-1);
  textFont(FontMSG);
  textAlign(CENTER);
  textSize(23);
  text("キ", 150, 84);
  text("ャ", 175, 82);
  text("ッ", 200, 80);
  text("プ", 225, 82);
  text("の", 250, 84);
  text("貯", 175, 107);
  text("金", 200, 105);
  text("箱", 225, 107);

  fill(0, 230, 0);
  textFont(FontMSG);
  textAlign(CENTER);
  textSize(19);
  text("キ", 150, 83);
  text("ャ", 175, 81);
  text("ッ", 200, 79);
  text("プ", 225, 81);
  text("の", 250, 83);
  text("貯", 175, 106);
  text("金", 200, 104);
  text("箱", 225, 106);

  //その他の文字
  fill(0);
  textFont(FontMSG);
  textAlign(CENTER);
  textSize(5);
  text("※PETボトルのキャップ以外は入れないでください。", 200, 310);
  textSize(6);
  text("PETボトルのキャップを回収し", 200, 180);
  text("僕がProcessingで遊ぶ活動です。", 200, 190);
  text("みなさまのご協力をお願いいたします。", 200, 200);

  //手
  noStroke();
  fill(#FFD0B4); //肌色
  quad(125+1, 180, 125+1, 165, 175, 150, 175, 165);
  quad(275-1, 130, 275-1, 115, 225, 130, 225, 145);
  ellipse(185, 155, 50, 20);
  ellipse(215, 140, 50, 20);


  //-----箱部分-----//
  stroke(0);
  strokeWeight(0.5);
  fill(200, 200, 255, 100);
  rect(125, 325, 150, 100);

  translate(100, 325);
  scale(1.0/3.0);
}


////場面が全体像のときのボタンやメニューウィンドウを描画するだけの関数
void DrawWholeSubs() {
  PFont FontMSG=createFont("MS-Gothic", 16);

  //----拡大ボタン----// 
  //ボタン
  stroke(0);
  strokeWeight(1);
  fill(-1, 120);
  rect(0, 0, 50, 50);

  //むしめがね
  stroke(0);
  strokeWeight(1);
  fill(-1, 120);
  quad(20+1.41, 30+1.41, 20-1.41, 30-1.41, 15-1.41, 35-1.41, 15+1.41, 35+1.41);
  ellipse(25, 25, 20, 20);
  ellipse(25, 25, 14, 14);

  //----リサイクルボタン----//
  //ボタン
  stroke(0);
  strokeWeight(1);
  fill(-1, 120);
  rect(575, 450, 50, 50);
  //マーク
  stroke(40);
  strokeWeight(4);
  noFill();
  arc(600, 475, 20, 20, PI/4-PI/2, PI/2);
  arc(600, 475, 20, 20, PI/2+PI/4, 3*PI/2);

  noStroke();
  fill(40);
  triangle(575+19, 450+35, 575+27, 450+30, 575+27, 450+40);
  triangle(575+31, 450+15, 575+23, 450+10, 575+23, 450+20);

  //----数値----//
  fill(0);
  textFont(FontMSG);
  textAlign(LEFT, CENTER);
  textSize(16);
  text("Recycled Caps: "+cRecycledSum, 640, 475);
}


////拡大場面のボタンやメニューウィンドウを描画するだけの関数
void DrawKakudaiSubs() {
  PFont FontMSG=createFont("MS-Gothic", 16);

  //-----拡大ボタン----// 
  //ボタン
  stroke(0);
  strokeWeight(1);
  fill(-1, 120);
  rect(0, 0, 50, 50);

  //むしめがね
  stroke(0);
  strokeWeight(1);
  fill(-1, 120);
  quad(20+1.41, 30+1.41, 20-1.41, 30-1.41, 15-1.41, 35-1.41, 15+1.41, 35+1.41);
  ellipse(25, 25, 20, 20);
  ellipse(25, 25, 14, 14);

  //----物体追加メニューウィンドウ----//
  //ウィンドウ
  stroke(0);
  strokeWeight(1);
  fill(-1, 120);
  rect(75, 375, 450, 100);

  //Capボタン
  stroke(0);
  strokeWeight(1);
  if (mode==0) {
    fill(255, 0, 0, 120);
  } else {
    fill(-1, 120);
  }
  rect(110, 405, 80, 40);

  fill(0);
  textFont(FontMSG);
  textAlign(CENTER, CENTER);
  textSize(15);
  text("Cap", 150, 425);

  //Bombボタン
  stroke(0);
  strokeWeight(1);
  if (mode==1) {
    fill(255, 0, 0, 120);
  } else {
    fill(-1, 120);
  }
  rect(260, 405, 80, 40);

  fill(0);
  textFont(FontMSG);
  textAlign(CENTER, CENTER);
  textSize(15);
  text("Bomb", 300, 425);

  //Wallボタン
  stroke(0);
  strokeWeight(1);
  if (mode==2) {
    fill(255, 0, 0, 120) ;
  } else {
    fill(-1, 120);
  }
  rect(410, 405, 80, 40);

  fill(0);
  textFont(FontMSG);
  textAlign(CENTER, CENTER);
  textSize(15);
  text("Wall", 450, 425);

  //----リサイクルボタン----//
  //ボタン
  stroke(0);
  strokeWeight(1);
  fill(-1, 120);
  rect(575, 450, 50, 50);
  //マーク
  stroke(40);
  strokeWeight(4);
  noFill();
  arc(600, 475, 20, 20, PI/4-PI/2, PI/2);
  arc(600, 475, 20, 20, PI/2+PI/4, 3*PI/2);

  noStroke();
  fill(40);
  triangle(575+19, 450+35, 575+27, 450+30, 575+27, 450+40);
  triangle(575+31, 450+15, 575+23, 450+10, 575+23, 450+20);

  //----数値----//
  fill(0);
  textFont(FontMSG);
  textAlign(LEFT, CENTER);
  textSize(16);
  text("Recycled Caps: "+cRecycledSum, 640, 475);
}


////諸処理を受けたキャップを描画するだけの関数
void DrawMono() {
  world.step();
  world.draw();
}


////ズームアウトするscaleをかける関数（描画の直前。諸処理は通常座標で行う。寄っている状態からズームアウトをかける）
void ZoomoutScaler() {
  scale(1.0/3.0);
  translate(100*3, 325*3);
}


////ズームアウトを解除する関数
void ZoomoutCuter() {
  translate(-100*3, -325*3);
  scale(3);
}


////任意の座標（重心）にキャップを追加するだけの関数（Fisica内部の処理）
//キャップは画面内に100個までしか置けないようにした。
//爆発処理のときにキャップの座標を取得して移動させるのでオブジェクト指向（？）を利用した。
void PutACap(float x, float y) {
  //画面内のキャップが99個以下のとき
  if (ccount<=99) {
    //キャップ追加
    cap[ccount]=new FPoly();
    cap[ccount].vertex(-SQ, SQ/2.0);
    cap[ccount].vertex(-SQ, -SQ/4.0);
    cap[ccount].vertex(-3*SQ/4.0, -SQ/2.0);
    cap[ccount].vertex(3*SQ/4.0, -SQ/2.0);
    cap[ccount].vertex(SQ, -SQ/4.0);
    cap[ccount].vertex(SQ, SQ/2.0);
    cap[ccount].vertex(-SQ, SQ/2.0);
    cap[ccount].setPosition(x, y);
    cap[ccount].setFill(random(255), random(255), random(255));
    world.add(cap[ccount]); 
    //通し番号におけるキャップの存在を追加
    cLife[ccount]=true;
    //画面内のキャップの数の変数を1増やす
    ccount++;
    //キャップ追加音（caper）
    caper.play(0);
  }
}


////任意の座標（重心）にボムを追加するだけの関数（Fisica内部の処理）
//ボムは画面内に20個までしか置けないようにした。
//爆発処理のときにボムを個別に指定して世界から消すのでオブジェクト指向（？）を利用した。
void PutABomb(float x, float y) {

  bAkiExistance=false;
  bAkinum=0;

  //[ボムについての配列20サイズについてforで繰り返し
  for (int RP=0; RP<=19; RP++) {
    //ボムの存在の配列bLife[]（サイズ20）のうちfalseのもの（＝空いているもの）を探して、
    //あればその通し番号をbAkinumに代入し、bAkiExistanceをtrueにする。
    //なければbAkiExistanceをfalseにする。
    if (bLife[RP]==false) {
      bAkiExistance=true;
      bAkinum=RP;
    }
  }
  //繰り返しおわり]

  //bAkiExistaceがtrueのとき（＝ボムが置ける空きがあるとき）
  if (bAkiExistance==true) {
    //通し番号bAkinumのところにボム追加
    bomb[bAkinum]=new FBox(SQ, SQ);
    bomb[bAkinum].setFill(100, 0, 0);
    bomb[bAkinum].setPosition(x, y);
    bomb[bAkinum].setVelocity(0, 300); //下に初速度を与えて爆弾を投下している感を出す
    world.add(bomb[bAkinum]);
    //通し番号におけるボムの存在を追加
    bLife[bAkinum]=true;
    //画面内のボムの数の変数を1増やす
    bcount++;
    //ボム追加音
    bomber.play(0);
  }
}


////任意の座標（重心）に壁を追加するだけの関数（Fisica内部の処理）
void PutAWall(float x, float y) {
  wall=new FBox(WL, WL);
  wall.setPosition(x, y);
  wall.setFill(0, 0, 0);
  wall.setStatic(true);
  wall.setGrabbable(false);
  world.add(wall);
}


////ボムの状態を更新する関数（爆発処理もここで行う）
void StepBomb() {
  //[ボムについての配列20サイズについてforで繰り返し
  for (int RPb=0; RPb<=19; RPb++) {
    if (bRed[RPb]==true) {
      //ボムが赤いときそのボムの赤い時間(bRedFrame[])を計測
      bRedFrame[RPb]++;
    }
    //赤い時間が90以上になったら
    if (bRedFrame[RPb]>=90) {
      //まずはボムの座標の取得
      bx[RPb]=bomb[RPb].getX();
      by[RPb]=bomb[RPb].getY();

      //キャップの座標取得、爆風で範囲内にいるキャップを飛ばす ここでは範囲はボムから半径150ピクセル
      //[[キャップについての配列20サイズについてforで繰り返し
      for (int RPc=0; RPc<=99; RPc++) {
        //通し番号RPcにおいてキャップが存在しているとき
        if (cLife[RPc]==true) {
          //キャップの座標の取得
          cx[RPc]=cap[RPc].getX();
          cy[RPc]=cap[RPc].getY();

          if (dist(bx[RPb], by[RPb], cx[RPc], cy[RPc])<150) {
            //キャップがボムから半径150ピクセルにいるとき、角度を計算して、距離に依存する速度でキャップを飛ばす
            bakhaTheta=atan2(cy[RPc]-by[RPb], cx[RPc]-bx[RPb]);
            bakhaVelocity=12*(150-dist(bx[RPb], by[RPb], cx[RPc], cy[RPc]));
            cap[RPc].setVelocity(bakhaVelocity*cos(bakhaTheta), bakhaVelocity*sin(bakhaTheta));
          }
        }
      }
      //繰り返しおわり]]

      //爆発音（bombgo）
      bombgo.play(0);

      //通し番号RPbにおけるボムの消失処理
      bRed[RPb]=false; //着火状態をオフに
      bbombon[RPb]=false; //音が鳴った状態という判定をオフに
      bLife[RPb]=false; //画面内のボムの存在をオフ
      world.remove(bomb[RPb]); //Fisicaの世界から消す
      bRedFrame[RPb]=0; //赤い状態の時間をゼロに
      bcount--; //画面内のボムの数の変数を1減らす
    }
  }
  //繰り返しおわり]
}


////キャップ回収を行い、ものを全て消す関数
void AllClear() {
  //キャップの数値的回収
  cRecycledSum=cRecycledSum+ccount;
  ccount=0;
  bcount=0;

  //配列の初期化
  for (int RP=0; RP<=19; RP++) {
    bLife[RP]=false;
    bRed[RP]=false;
    bbombon[RP]=false;
    bRedFrame[RP]=0;
    bx[RP]=0;
    by[RP]=0;
  }

  for (int RP=0; RP<=99; RP++) {
    cLife[RP]=false;
    cx[RP]=0;
    cy[RP]=0;
  }

  //Fisicaの初期化
  Fisica.init(this);
  world=new FWorld();
  world.setEdges(75, 0, 525, 300);

  //リサイクル音（recycler）
  recycler.play(0);
}


//----------以下、便利関数----------//
//一つ（一つ） #一つ

////ある座標が任意のrectの内部にあるかどうかを返す関数（そんなに楽になっていないかも）
boolean InRect(float usex, float usey, float x1, float y1, float x2, float y2) {
  boolean resultIR=false;
  if (usex>x1 && usex<x2 && usey>y1 && usey<y2) {
    resultIR=true;
  }
  return resultIR;
}