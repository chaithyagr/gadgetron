#include "CSI_utils.h"
#include <algorithm>
#include "cudaDeviceManager.h"
#include "complext.h"
using namespace Gadgetron;


template<class T> static __global__ void dft_kernel(complext<T>* __restrict__ kspace, const complext<T>* __restrict__ tspace, T* __restrict__ frequencies, unsigned int spiral_length, unsigned int echoes, unsigned int nfreqs,T dte, T dtt){
	const int idx = blockIdx.y*gridDim.x*blockDim.x + blockIdx.x*blockDim.x + threadIdx.x;
	if (idx < spiral_length*nfreqs ){
		complext<T> result = 0;
		T frequency = frequencies[idx/spiral_length];
		T time_offset = dtt*(idx%spiral_length);
		unsigned int kpoint = idx%spiral_length;
		for (unsigned int i =0; i < echoes; i++){
			result += exp(complext<T>(0,-frequency*(dte*i+time_offset)))*tspace[kpoint+i*spiral_length];
		}
		kspace[idx] = result;
	}
}

template<class T> static __global__ void dftH_kernel(const complext<T>* __restrict__ kspace, complext<T>* __restrict__ tspace, T* __restrict__ frequencies, unsigned int spiral_length, unsigned int echoes, unsigned int nfreqs,T dte, T dtt){
	const int idx = blockIdx.y*gridDim.x*blockDim.x + blockIdx.x*blockDim.x + threadIdx.x;
	if (idx < spiral_length*echoes ){
		complext<T> result = 0;
		unsigned int kpoint = idx%spiral_length;
		T timeshift = dte*idx/spiral_length+dtt*kpoint;

		for (unsigned int i =0; i < nfreqs; i++){
			result += exp(complext<T>(0,frequencies[i])*(timeshift))*kspace[kpoint+i*spiral_length];

		}
		tspace[idx] = result;
	}
}



template<class T>
void Gadgetron::CSI_dft(cuNDArray<complext<T> >* kspace,
		cuNDArray<complext<T> >* tspace, cuNDArray<T>* frequencies, T dtt, T dte) {

	size_t elements = kspace->get_number_of_elements();
	int threadsPerBlock = std::min<int>(elements,cudaDeviceManager::Instance()->max_blockdim());
	dim3 dimBlock(threadsPerBlock);
	int totalBlocksPerGrid = (elements+threadsPerBlock-1)/threadsPerBlock;
	dim3 dimGrid(totalBlocksPerGrid);

	if (totalBlocksPerGrid > cudaDeviceManager::Instance()->max_griddim())
		throw std::runtime_error("CSIOperator: Input dimensions too large");

	//size_t batchSize = dimGrid.x*dimBlock.x;
	cudaFuncSetCacheConfig(dft_kernel<T>,cudaFuncCachePreferL1);

	std::vector<size_t> dims = *tspace->get_dimensions();

	// Invoke kernel
	dft_kernel<T><<<dimGrid, dimBlock>>>(kspace->get_data_ptr(),tspace->get_data_ptr(),frequencies->get_data_ptr(),dims[0],dims[1], frequencies->get_number_of_elements(),dte,dtt);
	CHECK_FOR_CUDA_ERROR();


}

template<class T>
void Gadgetron::CSI_dftH(cuNDArray<complext<T> >* kspace,
		cuNDArray<complext<T> >* tspace, cuNDArray<T>* frequencies, T dtt, T dte) {
	size_t elements = tspace->get_number_of_elements();
	int threadsPerBlock = std::min<int>(elements,cudaDeviceManager::Instance()->max_blockdim());
	dim3 dimBlock(threadsPerBlock);
	int totalBlocksPerGrid = (elements+threadsPerBlock-1)/threadsPerBlock;
	dim3 dimGrid(totalBlocksPerGrid);

	if (totalBlocksPerGrid > cudaDeviceManager::Instance()->max_griddim())
		throw std::runtime_error("CSIOperator: Input dimensions too large");

	//size_t batchSize = dimGrid.x*dimBlock.x;
	cudaFuncSetCacheConfig(dftH_kernel<T>,cudaFuncCachePreferL1);

	std::vector<size_t> dims = *tspace->get_dimensions();

	// Invoke kernel
	dftH_kernel<T><<<dimGrid, dimBlock>>>(kspace->get_data_ptr(),tspace->get_data_ptr(),frequencies->get_data_ptr(),dims[0],dims[1], frequencies->get_number_of_elements(),dte,dtt);
	CHECK_FOR_CUDA_ERROR();

}

template void Gadgetron::CSI_dft<float>(cuNDArray<float_complext>* kspace,cuNDArray<float_complext>* tspace, cuNDArray<float>* frequencies, float dtt, float dte);
template void Gadgetron::CSI_dftH<float>(cuNDArray<float_complext>* kspace,cuNDArray<float_complext>* tspace, cuNDArray<float>* frequencies, float dtt, float dte);

