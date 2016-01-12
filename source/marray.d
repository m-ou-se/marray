import std.meta;
import std.range.primitives;
import std.stdio;

struct MultiArray(T, size_t N) {

	T* data;
	size_t[N] sizes;
	size_t[N] strides;

	static MultiArray allocate(in size_t[N] sizes ...) {
		MultiArray m;
		m.sizes = sizes;
		size_t p = 1;
		foreach_reverse (d, s; sizes) {
			m.strides[d] = p;
			p *= s;
		}
		m.data = new T[p].ptr;
		return m;
	}

	size_t[2] opSlice(size_t d)(size_t s, size_t e) const { return [s, e]; }

	size_t opDollar(size_t d)() const { return sizes[d]; }

	auto ref opIndex(Args...)(Args args) {
		enum isSlice(T) = is(T == size_t[2]);
		enum n_range_args = Filter!(isSlice, Args).length;
		enum new_N = N - args.length + n_range_args;
		T* new_data = data;
		size_t[new_N] new_sizes = void;
		size_t[new_N] new_strides = void;
		size_t dimension = 0;
		foreach (i, a; args) {
			static if (is(typeof(a) == size_t[2])) {
				new_sizes[dimension] = a[1] - a[0];
				new_strides[dimension] = strides[i];
				new_data += strides[i] * a[0];
				++dimension;
			} else {
				new_data += strides[i] * a;
			}
		}
		static if (new_N == 0) {
			return *new_data;
		} else {
			new_sizes[n_range_args .. $] = sizes[args.length .. $];
			new_strides[n_range_args .. $] = strides[args.length .. $];
			return MultiArray!(T, new_N)(new_data, new_sizes, new_strides);
		}
	}

	size_t length() const { return sizes[0]; }
	bool empty() const { return length == 0; }

	auto ref front() { return this[0]; }
	auto ref back() { return this[$ - 1]; }

	void popFront() { --sizes[0]; data += strides[0]; }
	void popBack() { --sizes[0]; }

	MultiArray save() { return this; }
}

private T[N - 1] removeIndex(T, size_t N)(in T[N] input, size_t index) {
	T[N - 1] output = void;
	output[0 .. index] = input[0 .. index];
	output[index .. $] = input[index + 1 .. $];
	return output;
}

static assert(isRandomAccessRange!(MultiArray!(int, 3)));
