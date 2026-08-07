/* This file is part of the Spring engine (GPL v2 or later), see LICENSE.html */

#ifndef RANGES_COMPAT_H
#define RANGES_COMPAT_H

#include <version>
#include <iterator>
#include <ranges>
#include <utility>

/*
 * std::views::enumerate is C++23 (P2164R9). libstdc++ ships it; libc++ does
 * not yet, so every TU using it fails to compile with AppleClang.
 *
 * The guard is the standard feature-test macro rather than __APPLE__: any
 * toolchain that has the real thing gets the real thing, and this whole file
 * collapses to a using-declaration the moment libc++ implements it. Nothing
 * here is macOS-specific, so it can go upstream as-is.
 */

namespace spring::views {

#ifdef __cpp_lib_ranges_enumerate

using std::views::enumerate;

#else

template<typename Rng>
class EnumerateView {
public:
	explicit EnumerateView(Rng& r): rng(r) {}

	class Iterator {
	public:
		using Inner = decltype(std::begin(std::declval<Rng&>()));

		Iterator(Inner i, std::ptrdiff_t n): it(i), idx(n) {}

		// Yields a prvalue pair<index, reference-to-element>, which is what the
		// call sites bind with `auto [i, v]` / `const auto& [i, v]`. Keeping the
		// element half a reference matters: copying it would silently change a
		// mutating loop into a no-op.
		auto operator * () const { return std::pair<std::ptrdiff_t, decltype(*it)>(idx, *it); }

		Iterator& operator ++ () { ++it; ++idx; return *this; }
		bool operator != (const Iterator& o) const { return it != o.it; }

	private:
		Inner it;
		std::ptrdiff_t idx;
	};

	auto begin() const { return Iterator(std::begin(rng), 0); }
	auto end  () const { return Iterator(std::end  (rng), 0); }

private:
	// A reference, so this must only be handed an lvalue that outlives the loop.
	// Every current call site passes a named container; a temporary would dangle.
	Rng& rng;
};

template<typename Rng>
auto enumerate(Rng&& r) { return EnumerateView<std::remove_reference_t<Rng>>(r); }

#endif

}

#endif // RANGES_COMPAT_H
