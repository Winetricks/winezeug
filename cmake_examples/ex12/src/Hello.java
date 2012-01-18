class Hello {
    public native void print_hello();

    public static void main(String[] argv) {
        System.loadLibrary("CHello");   // only needs to be done once
        Hello h = new Hello();
        h.print_hello();
    }
}
