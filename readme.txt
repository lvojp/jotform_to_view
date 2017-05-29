jotformからダウンロードしてきたcsvファイルを"jot_input.csv"とリネームしたものをmain.rbと同階層に置く。
実行するとviewというディレクトリが作成され、中にdat.csvが出来上がる。これがindesignで使うファイルになる。

同時にpicList.txtが作成され、wgetを使って./view/imgs/の中にびゅ〜で使う画像ファイルがダウンロードされてゆく。（通常、コメントアウトされている）

このパスがdat.csvに記されているので、indesignでデータ結合を使って呼び出して使う。
