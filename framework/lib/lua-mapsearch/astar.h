/*******************************************************************************
 * DANIEL'S ALGORITHM IMPLEMENTAIONS
 *
 *  /\  |  _   _  ._ o _|_ |_  ._ _   _ 
 * /--\ | (_| (_) |  |  |_ | | | | | _> 
 *         _|                      
 *
 * A* ALGORITHM
 * 
 * Features:
 *    In computer science, A* (pronounced "A star" ,is a computer algorithm
 * that is widely used in pathfinding and graph traversal, the process of
 * plotting an efficiently traversable path between points, called nodes. Noted 
 * for its performance and accuracy, it enjoys widespread use. (However, in 
 * practical travel-routing systems, it is generally outperformed by algorithms 
 * which can pre-process the graph to attain better performance.[1])
 *
 * http://en.wikipedia.org/wiki/A*_search_algorithm
 *
 ******************************************************************************/

#ifndef ALGO_ASTAR_H__
#define ALGO_ASTAR_H__

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
#include "heap.h"
#include "hash_table.h"
#include "array2d.h"
#include "lua-mapSearch.h"
#include "fputil.h"
#include <map>
#include <vector>
#include <list>
#include <set>

namespace alg {
	static const float xishu = 10.0;
	class Railway {
		public:
			int id;
			int x;
			int y;
			Railway() {
				id = 0;
			}
			Railway(int idd, int xx, int yy) {
				id = idd;
				x = xx;
				y = yy;
			}
			Railway(const Railway& n) {
				id = n.id;
				x = n.x;
				y = n.y;
			}
	};
	class AStar {
		public:
			static const unsigned int WALL = 500;
			static const unsigned int CHECK = 0;
			static const unsigned int MOD = 10000;

		private:
			Array2D<Graph>& m_grid;	
			// the openset
			Heap m_openset;
			// Estimated total cost from start to goal through y.
			std::vector<Graph*> &m_clear;
			std::map<int, std::vector<Railway*> *>& m_railway;
			std::map<int, unsigned long long>& m_railwayaid;
			std::map<unsigned long long, std::set<unsigned long long>*> &m_friendaid;
			std::list<Graph*> &m_ptr;
		public:
			AStar(Array2D<Graph> & grid, std::map<int, std::vector<Railway*> *>& railway, std::map<int, unsigned long long>& railwayaid, std::map<unsigned long long, std::set<unsigned long long>*>& friendaid, std::vector<Graph*> &mclear, std::list<Graph*> &mptr) : 
				m_grid(grid), m_railway(railway), m_railwayaid(railwayaid), m_friendaid(friendaid), m_clear(mclear), m_ptr(mptr), m_openset(grid.row()*grid.col()) {}

			std::list<Graph*>* GetPath(uint32_t x1, uint32_t y1, uint32_t x2, uint32_t y2, unsigned long long aid, float speed, float railwayTime, int nb = 1) {
				uint32_t nrow = m_grid.row();
				uint32_t ncol = m_grid.col();
				int count = 0;
				if (x1 >= nrow || y1 >= ncol || x2 >= nrow || y2 >= ncol) {
					printf("FindPath error1, astar.h x1=%d y1=%d x2=%d y2=%d aid=%lld\n", x1, y1, x2, y2, aid);
					return NULL;
				}
				Graph& startNode = m_grid(y1, x1);
				Graph& endNode = m_grid(y2, x2);
				if (startNode.subzone == WALL || endNode.subzone == WALL) {
					printf("FindPath error2, astar.h x1=%d y1=%d x2=%d y2=%d aid=%lld\n", x1, y1, x2, y2, aid);
					return NULL;
				}
				if(m_clear.size() > 0) {
					for(auto it = m_clear.begin(); it != m_clear.end(); it++) {
						Graph* tmpNode = *it;
						tmpNode->g = 0.0f;
						tmpNode->f = 0.0f;
						tmpNode->isclose = false;
						tmpNode->isopen = false;
						tmpNode->israilway = 0;
						tmpNode->parent = NULL;
					}
					m_clear.clear();
				}
				m_openset.Clear();
				startNode.isclose = false;
				startNode.isopen = true;
				startNode.g = 0.0f;
				startNode.f = startNode.g + estimate2(startNode, endNode, aid, speed, railwayTime);
				startNode.parent = NULL;
				if(IsUsableRailway(startNode.id, aid)) {
					startNode.israilway = 1;
				} else {
					startNode.israilway = 0;
				}
				m_openset.Add(&startNode);
				m_clear.push_back(&startNode);
				
				while(!m_openset.Empty()) {
					++count;
					Graph *e = m_openset.Remove();
					int	cx = e->x;
					int	cy = e->y;
					
					Graph& node = m_grid(cy, cx);
					node.isclose = true;
					node.isopen = false;
					SetVertex(node, endNode, aid, speed, railwayTime, nb);
					if(cx == endNode.x && cy == endNode.y) { // reconstruct path
						std::list<Graph*>::iterator itptr;
						if(m_ptr.empty()) {
							itptr = m_ptr.begin();
						} else {
							itptr = m_ptr.end();
						}
						itptr = m_ptr.insert(itptr, &endNode);
						Graph* tmp = m_grid(endNode.y, endNode.x).parent;
						while(tmp != NULL && !(tmp->x == startNode.x && tmp->y == startNode.y)) {
							itptr = m_ptr.insert(itptr, tmp);
							tmp = tmp->parent;
						}
						std::list<Graph*>::iterator itptr2 = itptr;
						--itptr2;
						if ((*itptr2) != &startNode) {
							itptr = m_ptr.insert(itptr, &startNode);
						}
						return &m_ptr;
					}
					//周围x个点
					for(int i=-nb; i<=nb; i++) {
						for(int j=-nb; j<=nb; j++) {
							int nx = cx+i, ny = cy+j;
							// exclude invalid position
							if (nx < 0 || nx >= (int)ncol || ny < 0 || ny >= (int)nrow) {
								continue;
							}
							// except the cur itself
							if(nx == cx && ny == cy) {
								continue;
							}
							// except the wall;
							Graph& neighbour = m_grid(ny, nx);
							if(neighbour.subzone == WALL || !(neighbour.subzone == CHECK || node.subzone == CHECK || neighbour.subzone == node.subzone)) {
								continue;
							}
							// exclude the neighbour in the closed set	
							if(neighbour.isclose) {
								continue;
							}
							if(!(-1<=i && i<=1 && -1<=j && j<=1) && (!IsUsableRailway(neighbour.id, aid) || !LineOfSight2(node.subzone, node.x, node.y, nx, ny))) {
								continue;
							}
							uint32_t keyneighbour = neighbour.id;
							m_clear.push_back(&neighbour);
							//we got a valid neighbour
							Graph& node2 = (!node.israilway && node.parent) ? *node.parent : node;
							float tentative = node2.g + estimate(neighbour, node2)/speed;
							if(neighbour.isopen) {
								if (neighbour.g > tentative) {
									neighbour.parent = &node2;
									neighbour.g = tentative;
									neighbour.f = neighbour.g + estimate2(neighbour, endNode, aid, speed, railwayTime);
									// neighbour.israilway = 0;
									m_openset.DecreaseKey(&neighbour);
								}
							} else {
								neighbour.parent = &node2;
								neighbour.g = tentative;
								neighbour.f = neighbour.g + estimate2(neighbour, endNode, aid, speed, railwayTime);
								neighbour.isopen = true;
								// neighbour.israilway = 0;
								m_openset.Add(&neighbour);
							}
						}
					}
					//火车站点直达点
					auto it = m_railway.find(e->id);
					if(it != m_railway.end() && IsUsableRailway(e->id, aid)) {
						std::vector<Railway*> *vec = it->second;
						for(auto it2=vec->begin();it2!=vec->end();it2++) {
							Railway* pr = *it2;
							int keyneighbour = pr->id;
							int	ny = keyneighbour/MOD;
							int	nx = keyneighbour%MOD;
							if (nx < 0 || nx >= (int)ncol || ny < 0 || ny >= (int)nrow) {
								continue;
							}
							if(nx == cx && ny == cy) {
								continue;
							}
							// except the wall;
							Graph& neighbour = m_grid(ny, nx);
							if(neighbour.subzone == WALL) {
								continue;
							}
							// exclude the neighbour in the closed set	
							if(neighbour.isclose) {
								continue;
							}
							if(!IsUsableRailway(keyneighbour, aid)) {
								continue;
							}
							//we got a valid neighbour
							m_clear.push_back(&neighbour);
							Graph& node2 = node;
							float tentative = node2.g + railwayTime;
							if(neighbour.isopen) {
								if (neighbour.g > tentative) {
									neighbour.parent = &node2;
									neighbour.g = tentative;
									neighbour.f = neighbour.g + estimate2(neighbour, endNode, aid, speed, railwayTime);
									neighbour.israilway = 1;
									m_openset.DecreaseKey(&neighbour);
								}
							} else {
								neighbour.parent = &node2;
								neighbour.g = tentative;
								neighbour.f = neighbour.g + estimate2(neighbour, endNode, aid, speed, railwayTime);
								neighbour.isopen = true;
								neighbour.israilway = 1;
								m_openset.Add(&neighbour);
							}
							node2.israilway = 1;
						}
					}
				}
				// haven't reached target
				printf("FindPath error3, astar.h x1=%d y1=%d x2=%d y2=%d aid=%lld\n", x1, y1, x2, y2, aid);
				return NULL;
			}
			/**
			 * Estimate the cost for going this way, such as:
			 * acrossing the swamp will be much slower than walking on the road.
			 * design for you game.
			 */
			inline float estimate(Graph& node1, Graph& node2) const {
				return sqrtf((node1.x-node2.x)*(node1.x-node2.x) + (node1.y-node2.y)*(node1.y-node2.y));
			}
			//深度遍历铁轨, 求最小f值
			float estimate2(Graph& node1, Graph& node2, unsigned long long aid, float speed, float railwayTime) {
				float f = sqrtf((node1.x-node2.x)*(node1.x-node2.x) + (node1.y-node2.y)*(node1.y-node2.y))/speed;
				auto it = m_railway.find(node1.id);
				if(it != m_railway.end() && IsUsableRailway(node1.id, aid)) {
					std::vector<Railway*> *vec = it->second;
					if(vec->size() > 0) {
						std::map<int, float> checkg;
						std::list<int> extend;
						checkg[node1.id] = 0;
						for(auto it2=vec->begin();it2!=vec->end();it2++) {
							Railway* tmp = *it2;
							if(IsUsableRailway(tmp->id, aid) && checkg.find(tmp->id) == checkg.end()) {
								float newg = railwayTime;
								float newf = newg + sqrtf((tmp->x-node2.x)*(tmp->x-node2.x) + (tmp->y-node2.y)*(tmp->y-node2.y))/speed;
								if(newf<f) {
									f = newf;
								}
								checkg[tmp->id] = newg;
								extend.push_back(tmp->id);
							}
						}
						while(!extend.empty()) {
							int id = extend.front();
							extend.pop_front();
							auto itt = m_railway.find(id);
							if(itt != m_railway.end()) {
								std::vector<Railway*> *vec = itt->second;
								if(vec->size() > 0) {
									for(auto it2=vec->begin();it2!=vec->end();it2++) {
										Railway* tmp = *it2;
										if(IsUsableRailway(tmp->id, aid) && checkg.find(tmp->id) == checkg.end()) {
											float newg = railwayTime;
											float newf = newg + sqrtf((tmp->x-node2.x)*(tmp->x-node2.x) + (tmp->y-node2.y)*(tmp->y-node2.y))/speed;
											if(newf<f) {
												f = newf;
											}
											checkg[tmp->id] = newg;
											extend.push_back(tmp->id);
										}
									}
								}
							}
						}
					}
				}
				return f;
			}
			bool LineOfSight(Graph& node, Graph& parent, unsigned long long aid) {
				if (node.israilway) {
					return true;
				}
				if (node.subzone == parent.subzone) {
					int x0 = node.x, y0 = node.y;
					int x1 = parent.x, y1 = parent.y;
					int dx = abs(x1 - x0);
					int dy = abs(y1 - y0);
					int err = dx - dy;
					int sx = (x0 < x1) ? 1 : -1;
					int sy = (y0 < y1) ? 1 : -1;
					int subzone;

					while(true) {
						subzone = m_grid(y0, x0).subzone;
						if (subzone == WALL || subzone != node.subzone) {
							return false;
						}
						if(x0 == x1 && y0 == y1) {
							break;
						}
						int e2 = 2*err;
						if (e2 > -dy) {
							err = err - dy;
							x0 = x0 + sx;
						}
						if (e2 < dx) {
							err = err + dx;
							y0 = y0 + sy;
						}
					}
					return true;
				}
				return false;
			}
			inline bool LineOfSight2(int subzone0, int x0, int y0, int x1, int y1) {
				int dx = abs(x1 - x0);
				int dy = abs(y1 - y0);
				int err = dx - dy;
				int sx = (x0 < x1) ? 1 : -1;
				int sy = (y0 < y1) ? 1 : -1;
				int subzone;

				while(true) {
					subzone = m_grid(y0, x0).subzone;
					if (subzone == WALL || subzone != subzone0) {
						return false;
					}
					if(x0 == x1 && y0 == y1) {
						break;
					}
					int e2 = 2*err;
					if (e2 > -dy) {
						err = err - dy;
						x0 = x0 + sx;
					}
					if (e2 < dx) {
						err = err + dx;
						y0 = y0 + sy;
					}
				}
				return true;
			}
			void SetVertex(Graph& node, Graph& endNode, unsigned long long aid, float speed, float railwayTime, int nb = 1) {
				if (node.parent != NULL && !node.israilway && !LineOfSight(node, *node.parent, aid)) {
					int nrow = (int)m_grid.row();
					int ncol = (int)m_grid.col();
					float minG = 0.0f;
					Graph* minParent = NULL;
					//周围x个点
					for(int i=-nb; i<=nb; i++) {
						for(int j=-nb; j<=nb; j++) {
							int nx = node.x+i, ny = node.y+j;
							// exclude invalid position
							if (nx < 0 || nx >= ncol || ny < 0 || ny >= nrow) {
								continue;
							}
							// except the cur itself
							if(nx == node.x && ny == node.y) {
								continue;
							}
							// except the wall;
							Graph& neighbour = m_grid(ny, nx);
							if(neighbour.subzone == WALL) {
								continue;
							}
							if(!(-1<=i && i<=1 && -1<=j && j<=1) && (!IsUsableRailway(neighbour.id, aid) || !LineOfSight2(node.subzone, node.x, node.y, nx, ny))) {
								continue;
							}
							if (neighbour.isclose) {
								float g = neighbour.g + estimate2(neighbour, node, aid, speed, railwayTime);
								if(minParent == NULL || g < minG) {
									minG = g;
									minParent = &neighbour;
								}
							}
						}
					}
					if(minParent != NULL) {
						node.parent = minParent;
						node.g = minG;
						node.f = node.g + estimate2(node, endNode, aid, speed, railwayTime);
						m_openset.DecreaseKey(&node);
					} else {
						printf("SetVertex error");
					}
				}
			}
			static inline int GetKey(int x, int y) {
				return y * MOD + x;
			}
			static inline int KeyToChunckKey(int key) {
				int	y = key/MOD;
				int x = key%MOD;
				return ((int)y/9) * MOD + ((int)x/9);
			}
			inline int xyToChunckKey(int x, int y) {
				return ((int)y/9) * MOD + ((int)x/9);
			}
			static inline unsigned int xToChunckX(unsigned int x) {
				return (unsigned int)x/9;
			}
			static inline int chunckxyToXY(int chunckxy) {
				return chunckxy * 9;
			}
			static inline int midchunckxyToXY(int chunckxy) {
				return chunckxy * 9 + 4;
			}
			inline bool IsUsableRailway(int key, unsigned long long aid) {
				if (aid > 0) {
					auto it = m_railwayaid.find(key);
					if (it != m_railwayaid.end()) {
						if(it->second == aid) {
							return true;
						}
						auto itt = m_friendaid.find(aid);
						if(itt != m_friendaid.end() && itt->second->find(it->second) != itt->second->end()) {
							return true;
						}
					}
				}
				return false;
			}
	};

}

#endif //
