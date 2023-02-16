using TinyKernels

using TinyKernels.CUDABackend

using CUDA

function test_function!(range, A, B, C, s)
    ix = (blockIdx().x - 1) * blockDim().x + threadIdx().x + (range[1][1] - 1)
    iy = (blockIdx().y - 1) * blockDim().y + threadIdx().y + (range[2][1] - 1)
    if ix ∈ axes(A, 1) && iy ∈ axes(A, 2)
        for _ in 1:10
            A[ix, iy] = B[ix, iy] + s * C[ix, iy]
        end
    end
    return
end

function main()
    nx, ny = 4096, 4096
    A = CUDA.zeros(Float64, nx, ny)
    B = CUDA.ones(Float64, nx, ny)
    C = 2.0.*CUDA.ones(Float64, nx, ny)
    s = -1.0

    ranges = ((4:nx-3 , 4:ny-3 ),
              (1:3    , 1:ny   ),
              (nx-2:nx, 1:ny   ),
              (4:nx-3 , 1:3    ),
              (4:nx-3 , ny-2:ny))

    test_kernel! = Kernel(test_function!, CUDADevice(), ranges)

    synchronize()

    inner_event, outer_events... = test_kernel!(A, B, C, s)

    wait(outer_events)
    sleep(1/30)
    wait(inner_event)

    return
end

for i in 1:5
    main()
end

CUDA.@profile main()