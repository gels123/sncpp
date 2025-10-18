#ifndef HEAP_H
#define HEAP_H

#include <stdio.h>
#include <iostream>
#include <vector>
#include <list>
#include "fputil.h"

#define DEFAULT_SIZE 100

class Graph {
public:
  Graph() {
    id = 0;
    x = 0;
    y = 0;
    subzone = 0;
    g = 0.0f;
    f = 0.0f;
    isopen = false;
    isclose = false;
    israilway = 0;
    parent = NULL;
    key = -1;
  }
  Graph(int id, int ix, int iy, int subzone) {
    id = id;
    x = ix;
    y = iy;
    subzone = subzone;
    g = 0.0f;
    f = 0.0f;
    isopen = false;
    isclose = false;
    israilway = 0;
    parent = NULL;
    key = -1;
  }
  Graph(const Graph &n) {
    id = n.id;
    x = n.x;
    y = n.y;
    subzone = n.subzone;
    g = n.g;
    f = n.f;
    isopen = n.isopen;
    isclose = n.isclose;
    israilway = n.israilway;
    parent = n.parent;
    key = n.key;
  }
  int id;
  int x;
  int y;
  int subzone;
  float g;
  float f;
  bool isopen;
  bool isclose;
  int israilway;
  Graph *parent;
  int key; //key in heap
};

class Heap {
public:
  Heap(int s = DEFAULT_SIZE)
  {
    count = 0;
    _elts.reserve(s);
  }

  ~Heap() {}

  /**
   * Return the size of the Heap.
   */
  unsigned int Size()
  {
    return _elts.size();
  }

  /**
   * Add object into Heap.
   */
  void Add(Graph *e)
  {
    e->key = count;
    _elts.push_back(e);
    count++;
    HeapifyUp(e->key);
  }

  /**
   * Remove the item with the lowest key from the Heap & re-heapify.
   */
  Graph *Remove()
  {
    if (Empty())
      return 0;
    count--;
    Graph *ans = _elts[0];
    _elts[0] = _elts[count];
    _elts[0]->key = 0;
    _elts.pop_back();
    HeapifyDown(0);

    return ans;
  }

  /**
   * Indicate that the key for a particular object has decreased.
   */
  void DecreaseKey(Graph *e)
  {
    HeapifyUp(e->key);
  }

  /**
   * Returns true if the object is in the Heap.
   */
  bool IsIn(Graph *e)
  {
    if ((unsigned long)e->key < _elts.size() && (_elts[e->key] == e))
      return true;
    return false;
  }

  /**
   * Returns true if no items are in the Heap.
   */
  bool Empty()
  {
    return count == 0;
  }

  /**
   * Clear the Heap.
   */
  void Clear()
  {
    count = 0;
    _elts.clear();
  }

private:
  void HeapifyUp(int index)
  {
    if (index == 0) return;
    int parent = (index-1)/2;

    if (fgreater(_elts[parent]->f, _elts[index]->f))
    {
      Graph *tmp = _elts[parent];
      _elts[parent] = _elts[index];
      _elts[index] = tmp;
      _elts[parent]->key = parent;
      _elts[index]->key = index;
      HeapifyUp(parent);
    }
  }

  void HeapifyDown(int index)
  {
    int child1 = index*2+1;
    int child2 = index*2+2;
    int which;
    // find smallest child
    if (child1 >= count)
      return;
    else if (child2 >= count)
      which = child1;
    else if (fless(_elts[child1]->f, _elts[child2]->f))
      which = child1;
    else
      which = child2;

    if (fless(_elts[which]->f, _elts[index]->f))
    {
      Graph *tmp = _elts[which];
      _elts[which] = _elts[index];
      _elts[index] = tmp;
      _elts[which]->key = which;
      _elts[index]->key = index;
      HeapifyDown(which);
    }
  }

private:
  std::vector<Graph *> _elts;
  int count;
};

#endif
