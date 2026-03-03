<?php
// Quiet Hacker - PHP Preview
declare(strict_types=1);

namespace QuietHacker;

const MAX_POOL_SIZE = 10;
const DEFAULT_TTL = 3600;

interface Cacheable
{
    public function cacheKey(): string;
    public function ttl(): int;
}

enum Status: string
{
    case Active = 'active';
    case Inactive = 'inactive';
    case Suspended = 'suspended';

    public function isActive(): bool
    {
        return $this === self::Active;
    }
}

readonly class User implements Cacheable
{
    public function __construct(
        private int $id,
        private string $name,
        private string $email,
        private Status $status = Status::Active,
    ) {}

    public function cacheKey(): string
    {
        return "user:{$this->id}";
    }

    public function ttl(): int
    {
        return DEFAULT_TTL;
    }

    public function toArray(): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'status' => $this->status->value,
        ];
    }
}

class Repository
{
    /** @var array<string, mixed> */
    private array $cache = [];

    public function __construct(
        private readonly \PDO $db,
    ) {}

    public function find(int $id): ?User
    {
        $key = "user:{$id}";

        if (isset($this->cache[$key])) {
            return $this->cache[$key];
        }

        $stmt = $this->db->prepare('SELECT * FROM users WHERE id = :id');
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);

        if ($row === false) {
            return null;
        }

        $user = new User(
            id: (int) $row['id'],
            name: $row['name'],
            email: $row['email'],
            status: Status::from($row['status']),
        );

        $this->cache[$key] = $user;
        return $user;
    }

    /**
     * @return User[]
     */
    public function findActive(): array
    {
        return array_filter(
            $this->cache,
            fn(User $u) => $u->toArray()['status'] === 'active'
        );
    }
}

// Usage
$users = [
    new User(1, 'Neo', 'neo@matrix.io'),
    new User(2, 'Trinity', 'trinity@matrix.io', Status::Active),
    new User(3, 'Ghost', 'ghost@void.net', Status::Suspended),
];

$active = array_filter($users, fn(User $u) => $u->toArray()['status'] === 'active');
$names = array_map(fn(User $u) => $u->toArray()['name'], $active);

echo "Active: " . implode(', ', $names) . PHP_EOL;
