mod fftbench;

fn main() {
    for _n in 0..10 {
        fftbench::fft_bench();
    }
}
