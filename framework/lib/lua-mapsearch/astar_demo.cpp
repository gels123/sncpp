#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "astar.h"

#define N 128

#define MARK 0xEE

int main(void)
{
	using namespace alg;

	Array2D<unsigned char> grid(N,N);
	grid.clear(0);
	srand(time(NULL));
	int i,j;
	
	for	(i=N/4;i<=3*N/4;i++) {
		grid(3*N/4,i) = AStar::WALL;
		grid(i,3*N/4) = AStar::WALL;
	}

	grid(0,0) = 0;
	grid(N-1,N-1) = 0;

	printf("search a path from (0,0) to (%d,%d)\n", N-1,N-1);
	for	(i=0;i<N;i++) {
		for(j=0;j<N;j++){
			if (grid(i,j) == AStar::WALL) {
				printf("%c", AStar::WALL);
			} else {
				printf(".");
			}
		}
		printf("\n");
	}

	printf("path:\n");
	AStar astar(grid);
	Path* ptr = astar.GetPath(0,0, N-1,N-1);

	Pos *tmpps = ptr->ps;
	for(i=0;i<ptr->count;i++){
		printf("(%d,%d)\t", tmpps->x, tmpps->y);
		grid(tmpps->x, tmpps->y) = MARK;
		++tmpps;
	}

	printf("\n");
	for	(i=0;i<N;i++) {
		for(j=0;j<N;j++){
			if (grid(i,j) == AStar::WALL) {
				printf("%c", AStar::WALL);
			} else if (grid(i,j) == MARK) {
				printf("@");
			} else {
				printf(".");
			}
		}
		printf("\n");
	}
	printf("\n");
	
	return 0;
}
