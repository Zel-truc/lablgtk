(* $Id$ *)

(* これを実行する前にLANG=ja_JP.EUCなどと指定しなければならない *)

(* cut-and-paste も対応していますが、editはうまくいきません *)

open GMain

let window = new GWindow.window
let box = new GPack.box `VERTICAL packing: window#add
let text = new GEdit.text editable: true packing: box#add
let font = Gdk.Font.load_fontset
    "-*-fixed-medium-r-normal--24-*-c-120-iso8859-1, \
     -*-fixed-medium-r-normal--24-*-jisx0208.1983-0, \
     -*-fixed-medium-r-normal--24-*-jisx0201.1976-0"
let button = new GButton.button label: "終了" packing: box#add
let label = new GMisc.label text:"これには影響しない" packing: box#add

let _ =
  window#connect#destroy callback:Main.quit;
  text#misc#realize ();
  text#insert "こんにちは" :font;
  let style = button#misc#style#copy in
  button#misc#set_style style;
  style#set_font font;
  style#set_bg [`NORMAL,`NAME "green"; `PRELIGHT,`NAME "red"];
  button#connect#clicked callback:Main.quit

let _ =
  window#show ();
  Main.main ()
