// Quiet Hacker - C++ Preview
#include <iostream>
#include <vector>
#include <memory>
#include <algorithm>
#include <string>
#include <functional>
#include <optional>

namespace hacker {

constexpr int MAX_NODES = 256;
constexpr double PI = 3.14159265358979;

template <typename T>
class RingBuffer {
public:
    explicit RingBuffer(size_t capacity)
        : buffer_(capacity), head_(0), tail_(0), size_(0) {}

    bool push(const T& value) {
        if (size_ >= buffer_.size()) return false;
        buffer_[tail_] = value;
        tail_ = (tail_ + 1) % buffer_.size();
        ++size_;
        return true;
    }

    std::optional<T> pop() {
        if (size_ == 0) return std::nullopt;
        T value = buffer_[head_];
        head_ = (head_ + 1) % buffer_.size();
        --size_;
        return value;
    }

    [[nodiscard]] bool empty() const { return size_ == 0; }
    [[nodiscard]] size_t size() const { return size_; }

private:
    std::vector<T> buffer_;
    size_t head_, tail_, size_;
};

struct Node {
    int id;
    std::string label;
    std::vector<std::shared_ptr<Node>> children;

    void traverse(std::function<void(const Node&)> visitor) const {
        visitor(*this);
        for (const auto& child : children) {
            child->traverse(visitor);
        }
    }
};

}  // namespace hacker

int main() {
    using namespace hacker;

    // Ring buffer demo
    RingBuffer<int> buffer(8);
    for (int i = 0; i < 10; ++i) {
        buffer.push(i * i);
    }

    while (!buffer.empty()) {
        auto val = buffer.pop();
        if (val.has_value()) {
            std::cout << *val << " ";
        }
    }
    std::cout << "\n";

    // Tree traversal
    auto root = std::make_shared<Node>(Node{
        .id = 0,
        .label = "root",
        .children = {
            std::make_shared<Node>(Node{1, "left", {}}),
            std::make_shared<Node>(Node{2, "right", {}}),
        }
    });

    root->traverse([](const Node& n) {
        std::cout << "[" << n.id << "] " << n.label << "\n";
    });

    return 0;
}
