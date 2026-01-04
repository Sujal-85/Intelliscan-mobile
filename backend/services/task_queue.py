"""
Task Queue Service for Smart Handwritten Data Recognition
Provides thread-safe background processing queue
"""
import threading
import queue
import logging
from typing import Callable, Any, Optional
from enum import Enum

class TaskStatus(Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"

class Task:
    """Represents a task in the queue"""
    
    def __init__(self, task_id: str, func: Callable, *args, **kwargs):
        self.task_id = task_id
        self.func = func
        self.args = args
        self.kwargs = kwargs
        self.status = TaskStatus.PENDING
        self.result = None
        self.error = None

class TaskQueueService:
    """Thread-safe task queue for background processing"""
    
    def __init__(self, max_workers: int = 4):
        self.max_workers = max_workers
        self.task_queue = queue.Queue()
        self.results = {}
        self.workers = []
        self.lock = threading.Lock()
        self.running = False
        
        # Start worker threads
        self.start_workers()
    
    def start_workers(self):
        """Start worker threads"""
        if not self.running:
            self.running = True
            for i in range(self.max_workers):
                worker = threading.Thread(target=self._worker, daemon=True)
                worker.start()
                self.workers.append(worker)
            logging.info(f"Started {self.max_workers} worker threads")
    
    def stop_workers(self):
        """Stop worker threads"""
        self.running = False
        # Add sentinel values to wake up workers
        for _ in range(self.max_workers):
            self.task_queue.put(None)
        
        # Wait for workers to finish
        for worker in self.workers:
            worker.join()
        
        self.workers.clear()
        logging.info("Stopped worker threads")
    
    def _worker(self):
        """Worker thread function"""
        while self.running:
            try:
                task = self.task_queue.get(timeout=1)
                if task is None:  # Sentinel value to stop worker
                    break
                
                with self.lock:
                    task.status = TaskStatus.IN_PROGRESS
                
                try:
                    # Execute the task
                    result = task.func(*task.args, **task.kwargs)
                    
                    with self.lock:
                        task.status = TaskStatus.COMPLETED
                        task.result = result
                        self.results[task.task_id] = task
                        
                except Exception as e:
                    with self.lock:
                        task.status = TaskStatus.FAILED
                        task.error = str(e)
                        self.results[task.task_id] = task
                    logging.error(f"Task {task.task_id} failed: {str(e)}")
                
                self.task_queue.task_done()
                
            except queue.Empty:
                continue
            except Exception as e:
                logging.error(f"Worker error: {str(e)}")
    
    def add_task(self, task_id: str, func: Callable, *args, **kwargs) -> str:
        """
        Add a task to the queue
        
        Args:
            task_id: Unique identifier for the task
            func: Function to execute
            *args: Positional arguments for the function
            **kwargs: Keyword arguments for the function
            
        Returns:
            Task ID
        """
        task = Task(task_id, func, *args, **kwargs)
        with self.lock:
            self.results[task_id] = task
        self.task_queue.put(task)
        return task_id
    
    def get_task_status(self, task_id: str) -> Optional[TaskStatus]:
        """
        Get the status of a task
        
        Args:
            task_id: Task identifier
            
        Returns:
            Task status or None if task not found
        """
        with self.lock:
            if task_id in self.results:
                return self.results[task_id].status
        return None
    
    def get_task_result(self, task_id: str) -> Any:
        """
        Get the result of a completed task
        
        Args:
            task_id: Task identifier
            
        Returns:
            Task result or None if task not completed or failed
        """
        with self.lock:
            if task_id in self.results:
                task = self.results[task_id]
                if task.status == TaskStatus.COMPLETED:
                    return task.result
                elif task.status == TaskStatus.FAILED:
                    raise Exception(f"Task failed: {task.error}")
        return None

# Global instance
_task_queue_service = None
_service_lock = threading.Lock()

def get_task_queue_service() -> TaskQueueService:
    """Get singleton instance of TaskQueueService"""
    global _task_queue_service
    if _task_queue_service is None:
        with _service_lock:
            if _task_queue_service is None:
                _task_queue_service = TaskQueueService()
    return _task_queue_service

# For testing purposes
if __name__ == "__main__":
    # This would be used for testing the service independently
    pass