# Replace
Experimental, replace Masonry apis with NSLayoutConstraints apis.

Masonry setup apis use many blocks as function returns and function parameters, which make code bigger than just NSLayoutConstraints. Current just finish replace mas_makeConstraints calls. Replace reduces 30KB (arm64, total binary size 4.58MB). And code is some of ugly 😅

https://github.com/SnapKit/Masonry/pull/522

Remove inline of _MASBoxValue to eliminate duplicate code size caused by inline function, which is 1.04KB(arm64, total binary size 4.58MB) for most includes call.

