(declaim (optimize (speed 3) (safety 0) (debug 0)))

(declaim (ftype (function (bit) (integer 0 4096)) predict))
(let ((cxt 1)
      (ct (make-array '(256 2) 
		      :element-type '(unsigned-byte 16) 
		      :initial-element 0)))
  (defun predict (y) 
    (declare (type (unsigned-byte 8) cxt))
    (incf (aref ct cxt y))
    (if (< 65534 (aref ct cxt y))
      (progn
	(setf (aref ct cxt 0) (ash (aref ct cxt 0) -1))
	(setf (aref ct cxt 1) (ash (aref ct cxt 1) -1))))
    (let ((new-cxt (+ cxt cxt y)))
      (setf cxt (if (<= 256 new-cxt) 1 new-cxt)))
    (floor (* 4096 (1+ (aref ct cxt 1))) 
	   (+ 2 (aref ct cxt 0) (aref ct cxt 1)))))

(defstruct ac
  (x1 0 	 :type (unsigned-byte 32))
  (x2 #xffffffff :type (unsigned-byte 32))
  (pr 2048 	 :type (unsigned-byte 16)))

(declaim (inline ac-flush))
(declaim (ftype (function (ac t)) ac-flush))
(defun ac-flush (a out)
  (write-byte (ash (ac-x1 a) -24) out))

(declaim (inline ac-rescale))
(declaim (ftype (function (ac)) ac-rescale))
(defun ac-rescale (a)
  (setf (ac-x1 a) (logand #XFFFFFFFF (ash (ac-x1 a) 8)))
  (setf (ac-x2 a) (logand #XFFFFFFFF (logior 255 (ash (ac-x2 a) 8)))))

(declaim (inline ac-encode-bit))
(declaim (ftype (function (ac bit t)) ac-encode-bit))
(defun ac-encode-bit (a y out)
  (let* ((range (- (ac-x2 a) (ac-x1 a)))
	 (xmid  (+ (ac-x1 a) 
		   (* (ash range -12) (ac-pr a)) 
		   (ash (* (logand range #xFFF) (ac-pr a)) -12))))
    (setf (ac-pr a) (predict y))
    (if (= y 1) (setf (ac-x2 a) xmid) (setf (ac-x1 a) (+ 1 xmid)))
    (loop :while (= 0 (ash (logxor (ac-x1 a) (ac-x2 a)) -24))
	  :do (ac-flush a out)
	  :do (ac-rescale a))))

(defun encode-stream (in-fname out-fname)
  (with-open-file 
    (in-stream in-fname 
	       :element-type      '(unsigned-byte 8) 
	       :direction         :input
	       :if-does-not-exist nil)
    (with-open-file 
      (out-stream out-fname 
		  :element-type      '(unsigned-byte 8) 
		  :direction 	     :output
		  :if-does-not-exist :create
		  :if-exists 	     :supersede)
      (let ((fsize (file-length in-stream)))
	(declare (type (unsigned-byte 32) fsize))
	(write-byte              (ash fsize -24)  out-stream)
	(write-byte (logand #xff (ash fsize -16)) out-stream)
	(write-byte (logand #xff (ash fsize -8 )) out-stream)
	(write-byte (logand #xff      fsize     ) out-stream))
      (let ((a (make-ac)))
	(loop 
	  :for c := (read-byte in-stream nil) :while c
	  :do (loop :for i :below 8 
		    :do (ac-encode-bit a (logand 1 (ash (the (unsigned-byte 8) c) (- i 7))) out-stream)))
	(ac-flush a out-stream)
	t))))
