{ stdenv, fetchurl }:

stdenv.mkDerivation {
  pname = "xserver-xorg-video-dummy";
  version = "0.3.8";

  src = fetchurl {
    url = "http://xorg.freedesktop.org/releases/individual/driver/xf86-video-dummy-0.4.1.tar.xz";
    sha256 = "1hqz8gxyf6avydblxnq6pzkw9l7ly3kn8ggcfr6x3kx7xlhz5isr";
  };

  buildInputs = [ ];

  meta = with stdenv.lib; {
    description = "Dummy video driver for Xorg";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}