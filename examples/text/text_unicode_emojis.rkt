#lang racket/base

;; raylib [text] example - unicode emojis (Racket FFI 完整翻译)
;; 对应 C: examples/text/text_unicode_emojis.c
;; 完整交互: hover 高亮、点击选中、多语言消息气泡

(require "../../raylib/raylib.rkt"
         racket/runtime-path)

(define-runtime-path resource-dir "../../../examples/text/resources")

(define EMOJI-PER-WIDTH 8)
(define EMOJI-PER-HEIGHT 4)
(define EMOJI-COUNT (* EMOJI-PER-WIDTH EMOJI-PER-HEIGHT))

(define screen-width 800)
(define screen-height 450)

(set-config-flags (bitwise-ior FLAG-MSAA-4X-HINT FLAG-VSYNC-HINT))
(init-window screen-width screen-height "raylib [text] example - unicode emojis")

;; 加载 3 种字体 (对应 C 原版)
(define font-default (load-font (path->string (build-path resource-dir "dejavu.fnt"))))
(define font-asian (load-font (path->string (build-path resource-dir "noto_cjk.fnt"))))
(define font-emoji (load-font (path->string (build-path resource-dir "symbola.fnt"))))

;; 180 个 emoji (对应 C 原版 emojiCodepoints, 按顺序每行 8 个)
(define emoji-codepoints
  (vector "🌀" "😀" "😂" "🤣" "😃" "😆" "😉" "😋"
          "😎" "😍" "😘" "😗" "😙" "😚" "🙂" "🤗"
          "🤩" "🤔" "🤨" "😐" "😑" "😶" "🙄" "😏"
          "😣" "😥" "😮" "🤐" "😯" "😪" "😫" "😴"
          "😌" "😛" "😝" "🤤" "😒" "😕" "🙃" "🤑"
          "😲" "🙁" "😖" "😞" "😟" "😤" "😢" "😭"
          "😦" "😩" "🤯" "😬" "😰" "😱" "😳" "🤪"
          "😵" "😡" "😠" "🤬" "😷" "🤒" "🤕" "🤢"
          "🤮" "🤧" "😇" "🤠" "🤫" "🤭" "🧐" "🤓"
          "😈" "👿" "👹" "👺" "💀" "👻" "👽" "👾"
          "🤖" "💩" "😺" "😸" "😹" "😻" "😽" "🙀"
          "😿" "🌾" "🌿" "🍀" "🍃" "🍇" "🍓" "🥝"
          "🍅" "🥥" "🥑" "🍆" "🥔" "🥕" "🌽" "🌶"
          "🥒" "🥦" "🍄" "🥜" "🌰" "🍞" "🥐" "🥖"
          "🥨" "🥞" "🧀" "🍖" "🍗" "🥩" "🥓" "🍔"
          "🍟" "🍕" "🌭" "🥪" "🌮" "🌯" "🥙" "🥚"
          "🍳" "🥘" "🍲" "🥣" "🥗" "🍿" "🥫" "🍱"
          "🍘" "🍝" "🍠" "🍢" "🍥" "🍡" "🥟" "🥡"
          "🍦" "🍪" "🎂" "🍰" "🥧" "🍫" "🍯" "🍼"
          "🥛" "🍵" "🍶" "🍾" "🍷" "🍻" "🥂" "🥃"
          "🥤" "🥢" "👁" "👅" "👄" "💋" "💘" "💓"
          "💗" "💙" "💛" "🧡" "💜" "🖤" "💝" "💟"
          "💌" "💤" "💢" "💣"))

;; 多语言消息列表 (text . language) — 共 33 条
(define messages
  (vector
    (cons "Falsches Üben von Xylophonmusik quält jeden größeren Zwerg" "German")
    (cons "Beiß nicht in die Hand, die dich füttert." "German")
    (cons "Außerordentliche Übel erfordern außerordentliche Mittel." "German")
    (cons "Կրնամ ապակի ուտել և ինծի անհանգիստ չըներ" "Armenian")
    (cons "Երբ որ կացինը եկաւ անտառ, ծառերը ասացին... «Կոտը մերոնցից է:»" "Armenian")
    (cons "Գառը՝ գարնան, ձիւնը՝ ձմռան" "Armenian")
    (cons "Jeżu klątw, spłódź Finom część gry hańb!" "Polish")
    (cons "Dobrymi chęciami jest piekło wybrukowane." "Polish")
    (cons "Îți mulțumesc că ai ales raylib.\nȘi sper să ai o zi bună!" "Romanian")
    (cons "Эх, чужак, общий съём цен шляп (юфть) вдрызг!" "Russian")
    (cons "Я люблю raylib!" "Russian")
    (cons "Молчи, скрывайся и таи\nИ чувства и мечты свои –\nПускай в душевной глубине\nИ всходят и зайдут оне\nКак звезды ясные в ночи-\nЛюбуйся ими – и молчи." "Russian")
    (cons "Voix ambiguë d'un cœur qui au zéphyr préfère les jattes de kiwi" "French")
    (cons "Benjamín pidió una bebida de kiwi y fresa; Noé, sin vergüenza, la más exquisita champaña del menú." "Spanish")
    (cons "Ταχίστη αλώπηξ βαφής ψημένη γη, δρασκελίζει υπέρ νωθρού κυνός" "Greek")
    (cons "Η καλύτερη άμυνα είναι η επίθεση." "Greek")
    (cons "Χρόνια και ζαμάνια!" "Greek")
    (cons "Πώς τα πας σήμερα;" "Greek")
    (cons "我能吞下玻璃而不伤身体。" "Chinese")
    (cons "你吃了吗？" "Chinese")
    (cons "不作不死。" "Chinese")
    (cons "最近好吗？" "Chinese")
    (cons "塞翁失马，焉知非福。" "Chinese")
    (cons "千军易得, 一将难求" "Chinese")
    (cons "万事开头难。" "Chinese")
    (cons "风无常顺，兵无常胜。" "Chinese")
    (cons "活到老，学到老。" "Chinese")
    (cons "一言既出，驷马难追。" "Chinese")
    (cons "路遥知马力，日久见人心" "Chinese")
    (cons "有理走遍天下，无理寸步难行。" "Chinese")
    (cons "猿も木から落ちる" "Japanese")
    (cons "亀の甲より年の功" "Japanese")
    (cons "うらやまし  思ひ切る時  猫の恋" "Japanese")
    (cons "虎穴に入らずんば虎子を得ず。" "Japanese")
    (cons "二兎を追う者は一兎をも得ず。" "Japanese")
    (cons "馬鹿は死ななきゃ治らない。" "Japanese")
    (cons "枯野路に　影かさなりて　わかれけり" "Japanese")
    (cons "繰り返し麦の畝縫ふ胡蝶哉" "Japanese")
    (cons "아득한 바다 위에 갈매기 두엇 날아 돈다.\n너훌너훌 시를 쓴다. 모르는 나라 글자다.\n널따란 하늘 복판에 나도 같이 시를 쓴다." "Korean")
    (cons "제 눈에 안경이다" "Korean")
    (cons "꿩 먹고 알 먹는다" "Korean")
    (cons "로마는 하루아침에 이루어진 것이 아니다" "Korean")
    (cons "고생 끝에 낙이 온다" "Korean")
    (cons "개천에서 용 난다" "Korean")
    (cons "안녕하세요?" "Korean")
    (cons "만나서 반갑습니다" "Korean")
    (cons "한국말 하실 줄 아세요?" "Korean")))

;; --- Emoji 运行时状态 ---
(define emoji-index (make-vector EMOJI-COUNT 0))
(define emoji-message (make-vector EMOJI-COUNT 0))
(define emoji-color (make-vector EMOJI-COUNT (color 255 255 255)))

(define-var hovered -1)
(define-var selected -1)
(define hovered-pos (vector2 0.0 0.0))
(define selected-pos (vector2 0.0 0.0))

;; 随机填充 emoji (对应 C 原版 RandomizeEmoji)
(define (randomize-emoji)
  (set-box! hovered -1)
  (set-box! selected -1)
  (define start (get-random-value 45 360))
  (for ([i (in-range EMOJI-COUNT)])
    (vector-set! emoji-index i (get-random-value 0 179))
    (vector-set! emoji-message i (get-random-value 0 (sub1 (vector-length messages))))
    (vector-set! emoji-color i
                 (fade (color-from-hsv
                         (exact->inexact (modulo (* start (add1 i)) 360)) 0.6 0.85) 0.8))))

(define (asian-language? lang)
  (ormap (lambda (x) (string=? lang x))
         (list "Chinese" "Korean" "Japanese")))

(randomize-emoji)
(set-target-fps 60)

;; --- 主循环 ---
(let loop ()
  (unless (window-should-close?)
    ;; ---- 更新 ----
    (when (is-key-pressed KEY-SPACE) (randomize-emoji))
    (define mouse (get-mouse-position))
    (when (and (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
               (not (= (unbox hovered) -1))
               (not (= (unbox hovered) (unbox selected))))
      (set-box! selected (unbox hovered))
      (set-vector2-x! selected-pos (vector2-x hovered-pos))
      (set-vector2-y! selected-pos (vector2-y hovered-pos)))

    ;; ---- 绘制 ----
    (begin-drawing)
    (clear-background RAYWHITE)

    (define ebs (exact->inexact (car font-emoji)))
    (set-box! hovered -1)
    (let* ([gx (box 28.8)]
           [gy (box 10.0)])

      ;; 绘制 emoji 网格
      (for ([i (in-range EMOJI-COUNT)])
        (let* ([es (vector-ref emoji-codepoints (vector-ref emoji-index i))]
               [ec (vector-ref emoji-color i)]
               [ex (unbox gx)] [ey (unbox gy)]
               [er (rectangle ex ey ebs ebs)]
               [sel? (= i (unbox selected))])
          ;; 画 emoji (hover 全色, 否则淡化)
          (if (check-collision-point-rec mouse er)
              (begin
                (draw-text-ex font-emoji es (vector2 ex ey) ebs 1.0 ec)
                (set-box! hovered i)
                (set-vector2-x! hovered-pos ex)
                (set-vector2-y! hovered-pos ey))
              (draw-text-ex font-emoji es (vector2 ex ey) ebs 1.0
                            (if sel? ec (fade LIGHTGRAY 0.4))))
          ;; 更新网格位置
          (if (and (not (= i 0)) (zero? (modulo (add1 i) EMOJI-PER-WIDTH)))
              (begin (set-box! gy (+ (unbox gy) ebs 24.25)) (set-box! gx 28.8))
              (set-box! gx (+ (unbox gx) ebs 28.8))))))

    ;; 聊天泡泡 (选中时)
    (when (not (= (unbox selected) -1))
      (let* ([si (unbox selected)]
             [mp (vector-ref messages (vector-ref emoji-message si))]
             [mt (car mp)] [ml (cdr mp)]
             [uf (if (asian-language? ml) font-asian font-default)]
             [fs (exact->inexact (car uf))]
             [sz (measure-text-ex uf mt fs 1.0)]
             [sw (min (vector2-x sz) 300.0)] [sh (vector2-y sz)]
             [sx (vector2-x selected-pos)] [sy (vector2-y selected-pos)]
             [bw (+ 40.0 sw)] [bh (+ 60.0 sh)]
             [bx (- sx 38.8)] [by (- sy bh)]
             [sc (vector-ref emoji-color si)])
        (when (< bx 10) (set! bx (+ bx 28)))
        (when (< by 10) (set! by (+ sy ebs 10.0)))
        (when (> (+ bx bw) screen-width) (set! bx (- screen-width bw 10)))
        (define mr (rectangle bx by bw bh))
        (define ta (vector2 sx (+ by bh)))
        (define tb (vector2 (+ sx 8) (+ by bh 10)))
        (define tc (vector2 (+ sx 10) (+ by bh)))
        (draw-rectangle-rec mr sc)
        (draw-triangle ta tb tc sc)
        (draw-text-ex uf mt (vector2 (+ bx 10.0) (+ by 10.0)) fs 1.0 WHITE)
        (let* ([info (format "~a ~a chars ~a bytes" ml
                               (get-codepoint-count mt) (string-length mt))]
               [isz (measure-text-ex (get-font-default) info 10.0 1.0)])
          (draw-text info (inexact->exact (round (- (+ bx bw) (vector2-x isz) 10)))
                     (inexact->exact (round (- (+ by bh) (vector2-y isz) 2))) 10 RAYWHITE))))

    ;; 底部说明文字
    (draw-text "These emojis have something to tell you, click each to find out!"
               (quotient (- screen-width 650) 2) (- screen-height 40) 20 GRAY)
    (draw-text "Each emoji is a unicode character from a font, not a texture... Press [SPACEBAR] to refresh"
               (quotient (- screen-width 484) 2) (- screen-height 16) 10 GRAY)

    (end-drawing)
    (loop)))

;; --- 清理 ---
(unload-font font-default)
(unload-font font-asian)
(unload-font font-emoji)
(close-window)