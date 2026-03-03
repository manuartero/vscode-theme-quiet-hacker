// Quiet Hacker - Go Preview
package main

import (
	"context"
	"fmt"
	"log"
	"sync"
	"time"
)

const (
	MaxWorkers  = 8
	QueueSize   = 100
	TaskTimeout = 5 * time.Second
)

type Task struct {
	ID      int
	Payload string
}

type Result struct {
	TaskID   int
	Output   string
	Duration time.Duration
	Err      error
}

type WorkerPool struct {
	tasks   chan Task
	results chan Result
	wg      sync.WaitGroup
}

func NewWorkerPool(workers, queueSize int) *WorkerPool {
	pool := &WorkerPool{
		tasks:   make(chan Task, queueSize),
		results: make(chan Result, queueSize),
	}

	for i := 0; i < workers; i++ {
		pool.wg.Add(1)
		go pool.worker(i)
	}

	return pool
}

func (p *WorkerPool) worker(id int) {
	defer p.wg.Done()

	for task := range p.tasks {
		start := time.Now()

		ctx, cancel := context.WithTimeout(context.Background(), TaskTimeout)
		result := p.process(ctx, task)
		cancel()

		result.Duration = time.Since(start)
		p.results <- result
	}
}

func (p *WorkerPool) process(ctx context.Context, task Task) Result {
	select {
	case <-ctx.Done():
		return Result{TaskID: task.ID, Err: ctx.Err()}
	case <-time.After(10 * time.Millisecond):
		output := fmt.Sprintf("processed:%s", task.Payload)
		return Result{TaskID: task.ID, Output: output}
	}
}

func (p *WorkerPool) Submit(task Task) {
	p.tasks <- task
}

func (p *WorkerPool) Shutdown() []Result {
	close(p.tasks)
	p.wg.Wait()
	close(p.results)

	var results []Result
	for r := range p.results {
		results = append(results, r)
	}
	return results
}

func main() {
	pool := NewWorkerPool(MaxWorkers, QueueSize)

	for i := 0; i < 20; i++ {
		pool.Submit(Task{
			ID:      i,
			Payload: fmt.Sprintf("item-%d", i),
		})
	}

	results := pool.Shutdown()
	for _, r := range results {
		if r.Err != nil {
			log.Printf("[ERROR] Task %d: %v", r.TaskID, r.Err)
			continue
		}
		fmt.Printf("[OK] Task %d: %s (%v)\n", r.TaskID, r.Output, r.Duration)
	}
}
