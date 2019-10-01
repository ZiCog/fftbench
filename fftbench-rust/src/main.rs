mod fftbench;

fn main() {
    for n in 0..10 {
        fftbench::fft_bench();
    }
}

