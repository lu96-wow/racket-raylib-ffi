#lang racket/base

;; core/raudio.rkt — 音频模块 (raudio.h)

(require ffi/unsafe
         "ffi-helpers.rkt")

(define _audio-callback
  (_cprocedure (list _pointer _uint) _void #:atomic? #t))

;; ── 设备 ──────────────────────────────────────────────────

(define init-audio-device     (get-ffi-obj "InitAudioDevice" lib (_fun -> _void)))
(define close-audio-device    (get-ffi-obj "CloseAudioDevice" lib (_fun -> _void)))
(define is-audio-device-ready? (get-ffi-obj "IsAudioDeviceReady" lib (_fun -> _stdbool)))
(define set-master-volume     (get-ffi-obj "SetMasterVolume" lib (_fun _float -> _void)))
(define get-master-volume     (get-ffi-obj "GetMasterVolume" lib (_fun -> _float)))

;; ── Wave ──────────────────────────────────────────────────

(define load-wave
  (let ([f (get-ffi-obj "LoadWave" lib (_fun _string -> (w : _wave-bytes)))])
    (lambda (file-name) (f file-name))))
(define load-wave-from-memory
  (let ([f (get-ffi-obj "LoadWaveFromMemory" lib
                        (_fun _string _pointer _int -> (w : _wave-bytes)))])
    (lambda (file-type data-ptr data-size) (f file-type data-ptr data-size))))
(define is-wave-valid
  (let ([f (get-ffi-obj "IsWaveValid" lib (_fun (w : _wave-bytes) -> _stdbool))])
    (lambda (wave) (f wave))))
(define unload-wave   (get-ffi-obj "UnloadWave" lib (_fun (w : _wave-bytes) -> _void)))
(define export-wave
  (let ([f (get-ffi-obj "ExportWave" lib (_fun (w : _wave-bytes) _string -> _stdbool))])
    (lambda (wave file-name) (f wave file-name))))
(define export-wave-as-code
  (let ([f (get-ffi-obj "ExportWaveAsCode" lib
                        (_fun (w : _wave-bytes) _string -> _stdbool))])
    (lambda (wave file-name) (f wave file-name))))
(define wave-copy
  (let ([f (get-ffi-obj "WaveCopy" lib (_fun (w : _wave-bytes) -> (out : _wave-bytes)))])
    (lambda (wave) (f wave))))
(define wave-crop      (get-ffi-obj "WaveCrop" lib (_fun _pointer _int _int -> _void)))
(define wave-format    (get-ffi-obj "WaveFormat" lib (_fun _pointer _int _int _int -> _void)))
(define load-wave-samples (get-ffi-obj "LoadWaveSamples" lib
                                       (_fun (w : _wave-bytes) -> _pointer)))
(define unload-wave-samples (get-ffi-obj "UnloadWaveSamples" lib (_fun _pointer -> _void)))

;; ── Sound ─────────────────────────────────────────────────

(define load-sound
  (let ([f (get-ffi-obj "LoadSound" lib (_fun _string -> (s : _sound-bytes)))])
    (lambda (file-name) (f file-name))))
(define load-sound-from-wave
  (let ([f (get-ffi-obj "LoadSoundFromWave" lib
                        (_fun (w : _wave-bytes) -> (s : _sound-bytes)))])
    (lambda (wave) (f wave))))
(define load-sound-alias
  (let ([f (get-ffi-obj "LoadSoundAlias" lib
                        (_fun (s : _sound-bytes) -> (a : _sound-bytes)))])
    (lambda (source) (f source))))
(define is-sound-valid
  (let ([f (get-ffi-obj "IsSoundValid" lib (_fun (s : _sound-bytes) -> _stdbool))])
    (lambda (sound) (f sound))))
(define update-sound (get-ffi-obj "UpdateSound" lib (_fun _pointer _pointer _int -> _void)))
(define unload-sound (get-ffi-obj "UnloadSound" lib (_fun (s : _sound-bytes) -> _void)))
(define unload-sound-alias (get-ffi-obj "UnloadSoundAlias" lib
                                        (_fun (s : _sound-bytes) -> _void)))
(define play-sound  (get-ffi-obj "PlaySound" lib (_fun (s : _sound-bytes) -> _void)))
(define stop-sound  (get-ffi-obj "StopSound" lib (_fun (s : _sound-bytes) -> _void)))
(define pause-sound (get-ffi-obj "PauseSound" lib (_fun (s : _sound-bytes) -> _void)))
(define resume-sound (get-ffi-obj "ResumeSound" lib (_fun (s : _sound-bytes) -> _void)))
(define is-sound-playing?
  (let ([f (get-ffi-obj "IsSoundPlaying" lib (_fun (s : _sound-bytes) -> _stdbool))])
    (lambda (sound) (f sound))))
(define set-sound-volume (get-ffi-obj "SetSoundVolume" lib
                                      (_fun (s : _sound-bytes) _float -> _void)))
(define set-sound-pitch  (get-ffi-obj "SetSoundPitch" lib
                                      (_fun (s : _sound-bytes) _float -> _void)))
(define set-sound-pan    (get-ffi-obj "SetSoundPan" lib
                                      (_fun (s : _sound-bytes) _float -> _void)))

;; ── Music ─────────────────────────────────────────────────

(define load-music-stream
  (let ([f (get-ffi-obj "LoadMusicStream" lib (_fun _string -> (m : _music-bytes)))])
    (lambda (file-name) (f file-name))))
(define load-music-stream-from-memory
  (let ([f (get-ffi-obj "LoadMusicStreamFromMemory" lib
                        (_fun _string _pointer _int -> (m : _music-bytes)))])
    (lambda (file-type data-ptr data-size) (f file-type data-ptr data-size))))
(define is-music-valid
  (let ([f (get-ffi-obj "IsMusicValid" lib (_fun (m : _music-bytes) -> _stdbool))])
    (lambda (music) (f music))))
(define unload-music-stream
  (get-ffi-obj "UnloadMusicStream" lib (_fun (m : _music-bytes) -> _void)))
(define play-music-stream
  (get-ffi-obj "PlayMusicStream" lib (_fun (m : _music-bytes) -> _void)))
(define is-music-stream-playing?
  (let ([f (get-ffi-obj "IsMusicStreamPlaying" lib
                        (_fun (m : _music-bytes) -> _stdbool))])
    (lambda (music) (f music))))
(define update-music-stream
  (get-ffi-obj "UpdateMusicStream" lib (_fun (m : _music-bytes) -> _void)))
(define stop-music-stream
  (get-ffi-obj "StopMusicStream" lib (_fun (m : _music-bytes) -> _void)))
(define pause-music-stream
  (get-ffi-obj "PauseMusicStream" lib (_fun (m : _music-bytes) -> _void)))
(define resume-music-stream
  (get-ffi-obj "ResumeMusicStream" lib (_fun (m : _music-bytes) -> _void)))
(define seek-music-stream
  (get-ffi-obj "SeekMusicStream" lib (_fun (m : _music-bytes) _float -> _void)))
(define set-music-volume
  (get-ffi-obj "SetMusicVolume" lib (_fun (m : _music-bytes) _float -> _void)))
(define set-music-pitch
  (get-ffi-obj "SetMusicPitch" lib (_fun (m : _music-bytes) _float -> _void)))
(define set-music-pan
  (get-ffi-obj "SetMusicPan" lib (_fun (m : _music-bytes) _float -> _void)))
(define get-music-time-length
  (let ([f (get-ffi-obj "GetMusicTimeLength" lib
                        (_fun (m : _music-bytes) -> _float))])
    (lambda (music) (f music))))
(define get-music-time-played
  (let ([f (get-ffi-obj "GetMusicTimePlayed" lib
                        (_fun (m : _music-bytes) -> _float))])
    (lambda (music) (f music))))

;; ── AudioStream ───────────────────────────────────────────

(define load-audio-stream
  (get-ffi-obj "LoadAudioStream" lib
               (_fun _uint _uint _uint -> (s : _audio-stream-bytes))))
(define is-audio-stream-valid
  (get-ffi-obj "IsAudioStreamValid" lib
               (_fun (s : _audio-stream-bytes) -> _stdbool)))
(define unload-audio-stream
  (get-ffi-obj "UnloadAudioStream" lib (_fun (s : _audio-stream-bytes) -> _void)))
(define update-audio-stream
  (get-ffi-obj "UpdateAudioStream" lib
               (_fun (s : _audio-stream-bytes) _pointer _int -> _void)))
(define is-audio-stream-processed?
  (get-ffi-obj "IsAudioStreamProcessed" lib
               (_fun (s : _audio-stream-bytes) -> _stdbool)))
(define play-audio-stream
  (get-ffi-obj "PlayAudioStream" lib (_fun (s : _audio-stream-bytes) -> _void)))
(define pause-audio-stream
  (get-ffi-obj "PauseAudioStream" lib (_fun (s : _audio-stream-bytes) -> _void)))
(define resume-audio-stream
  (get-ffi-obj "ResumeAudioStream" lib (_fun (s : _audio-stream-bytes) -> _void)))
(define is-audio-stream-playing?
  (get-ffi-obj "IsAudioStreamPlaying" lib
               (_fun (s : _audio-stream-bytes) -> _stdbool)))
(define stop-audio-stream
  (get-ffi-obj "StopAudioStream" lib (_fun (s : _audio-stream-bytes) -> _void)))
(define set-audio-stream-volume
  (get-ffi-obj "SetAudioStreamVolume" lib
               (_fun (s : _audio-stream-bytes) _float -> _void)))
(define set-audio-stream-pitch
  (get-ffi-obj "SetAudioStreamPitch" lib
               (_fun (s : _audio-stream-bytes) _float -> _void)))
(define set-audio-stream-pan
  (get-ffi-obj "SetAudioStreamPan" lib
               (_fun (s : _audio-stream-bytes) _float -> _void)))
(define set-audio-stream-buffer-size-default
  (get-ffi-obj "SetAudioStreamBufferSizeDefault" lib (_fun _int -> _void)))
(define set-audio-stream-callback
  (get-ffi-obj "SetAudioStreamCallback" lib
               (_fun (s : _audio-stream-bytes) _audio-callback -> _void)))
(define attach-audio-stream-processor
  (get-ffi-obj "AttachAudioStreamProcessor" lib
               (_fun (s : _audio-stream-bytes) _audio-callback -> _void)))
(define detach-audio-stream-processor
  (get-ffi-obj "DetachAudioStreamProcessor" lib
               (_fun (s : _audio-stream-bytes) _audio-callback -> _void)))
(define attach-audio-mixed-processor
  (get-ffi-obj "AttachAudioMixedProcessor" lib (_fun _audio-callback -> _void)))
(define detach-audio-mixed-processor
  (get-ffi-obj "DetachAudioMixedProcessor" lib (_fun _audio-callback -> _void)))

(provide
 init-audio-device close-audio-device is-audio-device-ready?
 set-master-volume get-master-volume
 load-wave load-wave-from-memory is-wave-valid unload-wave
 export-wave export-wave-as-code wave-copy wave-crop wave-format
 load-wave-samples unload-wave-samples
 load-sound load-sound-from-wave load-sound-alias is-sound-valid
 update-sound unload-sound unload-sound-alias
 play-sound stop-sound pause-sound resume-sound is-sound-playing?
 set-sound-volume set-sound-pitch set-sound-pan
 load-music-stream load-music-stream-from-memory is-music-valid
 unload-music-stream play-music-stream is-music-stream-playing?
 update-music-stream stop-music-stream pause-music-stream resume-music-stream
 seek-music-stream set-music-volume set-music-pitch set-music-pan
 get-music-time-length get-music-time-played
 load-audio-stream is-audio-stream-valid unload-audio-stream
 update-audio-stream is-audio-stream-processed?
 play-audio-stream pause-audio-stream resume-audio-stream
 is-audio-stream-playing? stop-audio-stream
 set-audio-stream-volume set-audio-stream-pitch set-audio-stream-pan
 set-audio-stream-buffer-size-default set-audio-stream-callback
 attach-audio-stream-processor detach-audio-stream-processor
 attach-audio-mixed-processor detach-audio-mixed-processor)
