case "$1" in
    # buster
    10.0) echo "http://snapshot.debian.org/archive/debian/20190706T025754Z" ;;
    10.1) echo "http://snapshot.debian.org/archive/debian/20190908T172415Z" ;;
    10.2) echo "http://snapshot.debian.org/archive/debian/20191116T030727Z" ;;
    10.3) echo "http://snapshot.debian.org/archive/debian/20200208T030002Z" ;;
    10.4) echo "http://snapshot.debian.org/archive/debian/20200509T025130Z" ;;
    10.5) echo "http://snapshot.debian.org/archive/debian/20200801T030228Z" ;;
    10.6) echo "http://snapshot.debian.org/archive/debian/20200926T035837Z" ;;
    10.7) echo "http://snapshot.debian.org/archive/debian/20201205T034710Z" ;;
    10.8) echo "http://snapshot.debian.org/archive/debian/20210206T032313Z" ;;
    10.9) echo "http://snapshot.debian.org/archive/debian/20210327T030822Z" ;;
    10.10) echo "http://snapshot.debian.org/archive/debian/20210619T031526Z" ;;
    10.11) echo "http://snapshot.debian.org/archive/debian/20211019T025145Z" ;;
    10.12) echo "http://snapshot.debian.org/archive/debian/20220326T025251Z" ;;
    # bullseye
    11.0) echo "http://snapshot.debian.org/archive/debian/20210814T212851Z" ;;
    11.1) echo "http://snapshot.debian.org/archive/debian/20211009T024746Z" ;;
    11.2) echo "http://snapshot.debian.org/archive/debian/20211218T031014Z" ;;
    11.3) echo "http://snapshot.debian.org/archive/debian/20220326T025251Z" ;;
    *)
        echo "Unknown Debian version number '$1'!" 1>&2
        exit 1
esac
