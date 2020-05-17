;;; ob-diagrams.el -*- lexical-binding: t; -*-

;;; ob-diagrams.el --- org-babel support for diagrams generation.

;; Copyright (C) 2018 emacsbliss

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Org-Babel support for generating various diagrams.

;;; Requirements:

;; diagrams (for sequence/flowchart/dot/railroad diagram) | https://github.com/francoislaberge/diagrams
;; state machine cat (for statemachine diagram) | https://github.com/sverweij/state-machine-cat
;; erd (for ERD diagram) | https://github.com/BurntSushi/erd
;;

;;; Code:
(require 'ob)
(require 'ob-eval)

(defvar org-babel-default-header-args:diagrams
  '((:results . "file") (:type . "type") (:exports . "results"))
  "Default arguments for evaluating a diagrams source block.")

(defcustom ob-diagrams-cli "~/node_modules/.bin/diagrams"
  "Path to executable for flowchart/sequence/dot/railroad diagrams."
  :group 'org-babel
  :type 'string)

(defcustom ob-diagrams-sm-cli "~/node_modules/.bin/smcat"
  "Path to executable for generating state machine diagram."
  :group 'org-babel
  :type 'string)

(defcustom ob-diagrams-erd-cli "~/Library/Haskell/bin/erd"
  "Path to executable for generating erd diagram."
  :group 'org-babel
  :type 'string)

(defvar ob-diagrams-chart-type-cli-alist
  nil)

(defun cmd-for-chart-type(chart-type cli temp-file out-file)
  (cond ((string-equal chart-type "erd")
         (format "%s -i %s -o %s" (shell-quote-argument cli)
            (org-babel-process-file-name temp-file)
            (org-babel-process-file-name out-file)))

        ((string-equal chart-type "statemachine")
         (format "%s %s -o %s" (shell-quote-argument cli)
            (org-babel-process-file-name temp-file)
            (org-babel-process-file-name out-file)))

        (t (format "%s %s %s %s" (shell-quote-argument cli)
                   chart-type
            (org-babel-process-file-name temp-file)
            (org-babel-process-file-name out-file))))
)


(defun org-babel-execute:diagrams (body params)
  (let* ((out-file (or (cdr (assoc :file params))
                       (error "diagrams requires a \":file\" header argument")))
         (chart-type (or (cdr (assoc :type params))
                       (error "diagrams requires a \":type\" header argument")))
         (temp-file (org-babel-temp-file "diagrams-"))
         (ob-diagrams-chart-type-cli-alist
          `(("statemachine" . ,ob-diagrams-sm-cli)
            ("erd" . ,ob-diagrams-erd-cli)
            ("flowchart" . ,ob-diagrams-cli)
            ("sequence" . ,ob-diagrams-cli)
            ("dot" . ,ob-diagrams-cli)
            ("railroad" . ,ob-diagrams-cli)
            ))
         (cli (assoc chart-type ob-diagrams-chart-type-cli-alist))
         (cmd nil))

    (unless cli
      (error "unrecognized chart type: %s" chart-type))

    (setq cli (expand-file-name (cdr cli)))

    (unless (file-exists-p cli)
      (error "could not find executable at %s" cli))

    (setq cmd (cmd-for-chart-type chart-type cli temp-file out-file))
    (with-temp-file temp-file (insert body))
    (message "%s" cmd)
    (org-babel-eval cmd "")
    nil))

(provide 'ob-diagrams)
;;; ob-diagrams.el ends here
