﻿#include "roadnet_world.h"
#include "roadnet_bfs.h"
#include <assert.h>

namespace roadnet {
    template <typename T, typename F>
    static void ary_call(world& w, uint64_t ti, T& ary, F func) {
        size_t N = ary.size();
        for (size_t i = 0; i < N; ++i) {
            (ary[i].*func)(w, ti);
        }
    }

    static constexpr direction reverse(direction dir) {
        switch (dir) {
        case direction::l: return direction::r;
        case direction::t: return direction::b;
        case direction::r: return direction::l;
        case direction::b: return direction::t;
        case direction::n: default: return direction::n;
        }
    }

    static constexpr loction move(loction loc, direction dir) {
        switch (dir) {
        case direction::l: loc.x -= 1; break;
        case direction::t: loc.y -= 1; break;
        case direction::r: loc.x += 1; break;
        case direction::b: loc.y += 1; break;
        case direction::n: default: break;
        }
        return loc;
    }

    // every 2 bits represent one direction of a road, 00 means nothing, 01 means road, 10 means roadside, total 8 bits represent 4 directions
    static constexpr uint8_t makeMask(const char* maskstr) {
        uint8_t m = 0;
        m |= maskstr[0] != '_'? (1 << (uint8_t)direction::l): 0;
        m |= maskstr[1] != '_'? (1 << (uint8_t)direction::t): 0;
        m |= maskstr[2] != '_'? (1 << (uint8_t)direction::r): 0;
        m |= maskstr[3] != '_'? (1 << (uint8_t)direction::b): 0;
        return m;
    }

    static constexpr uint8_t mask(wchar_t c) {
        switch (c) {
        case L'\0': case L' ': return makeMask("____");
        case L'║': return makeMask("_T_B");
        case L'═': return makeMask("L_R_");
        case L'╔': return makeMask("__RB");
        case L'╠': return makeMask("_TRB");
        case L'╚': return makeMask("_TR_");
        case L'╦': return makeMask("L_RB");
        case L'╬': return makeMask("LTRB");
        case L'╩': return makeMask("LTR_");
        case L'╗': return makeMask("L__B");
        case L'╣': return makeMask("LT_B");
        case L'╝': return makeMask("LT__");
        case L'>': return makeMask("L___");
        case L'v': return makeMask("_T__");
        case L'<': return makeMask("__R_");
        case L'^': return makeMask("___B");
        default: assert(false); return 0;
        }
    }

    static constexpr bool isValidRoadType(uint8_t m, RoadType t) {
        if (t < 16) {
            // cross
            return m & ((1 << (t & 0x03)) | (1 << ((t >> 2) & 0x03)));
        }
        else {
            // in / out
            return m & (1 << (t & 0x03));
        }
    }

    static constexpr bool isCross(uint8_t m) {
        switch (m) {
        case mask(L' '):
        case mask(L'║'):
        case mask(L'═'):
        case mask(L'>'):
        case mask(L'v'):
        case mask(L'<'):
        case mask(L'^'):
        case mask(L'╔'):
        case mask(L'╚'):
        case mask(L'╗'):
        case mask(L'╝'):
        default:
            return false;
        case mask(L'╠'):
        case mask(L'╦'):
        case mask(L'╬'):
        case mask(L'╩'):
        case mask(L'╣'):
            return true;
        }
    }
    
    static constexpr direction nextDirection(uint8_t m, direction dir) {
        switch (m) {
        case mask(L'║'):
            switch (dir) {
            case direction::t: return direction::t;
            case direction::b: return direction::b;
            default: break;
            }
            break;
        case mask(L'═'):
            switch (dir) {
            case direction::l: return direction::l;
            case direction::r: return direction::r;
            default: break;
            }
            break;
        case mask(L'>'):
            switch (dir) {
            case direction::r: return direction::l;
            default: break;
            }
            break;
        case mask(L'v'):
            switch (dir) {
            case direction::b: return direction::t;
            default: break;
            }
            break;
        case mask(L'<'):
            switch (dir) {
            case direction::l: return direction::r;
            default: break;
            }
            break;
        case mask(L'^'):
            switch (dir) {
            case direction::t: return direction::b;
            default: break;
            }
            break;
        case mask(L'╔'):
            switch (dir) {
            case direction::l: return direction::b;
            case direction::t: return direction::r;
            default: break;
            }
            break;
        case mask(L'╚'):
            switch (dir) {
            case direction::l: return direction::t;
            case direction::b: return direction::r;
            default: break;
            }
            break;
        case mask(L'╗'):
            switch (dir) {
            case direction::r: return direction::b;
            case direction::t: return direction::l;
            default: break;
            }
            break;
        case mask(L'╝'):
            switch (dir) {
            case direction::r: return direction::t;
            case direction::b: return direction::l;
            default: break;
            }
            break;
        default: break;
        }
        assert(false);
        return direction::n;
    }

    static constexpr direction straightDirection(uint8_t m, uint8_t z) {
        switch (m) {
        case mask(L'║'):
            return (z & 0x10)
                ? direction::t
                : direction::b
                ;
        case mask(L'═'):
            return (z & 0x10)
                ? direction::r
                : direction::l
                ;
        case mask(L'>'):
            return direction::l;
        case mask(L'v'):
            return direction::t;
        case mask(L'<'):
            return direction::r;
        case mask(L'^'):
            return direction::b;
        case mask(L'╔'):
            return (z & 0x10)
                ? direction::r
                : direction::b
                ;
        case mask(L'╚'):
            return (z & 0x10)
                ? direction::t
                : direction::r
                ;
        case mask(L'╗'):
            return (z & 0x10)
                ? direction::b
                : direction::l
                ;
        case mask(L'╝'):
            return (z & 0x10)
                ? direction::t
                : direction::l
                ;
        default: break;
        }
        return direction::n;
    }

    struct NeighborResult {
        loction   l;
        direction dir;
        uint16_t  n;
    };
    static constexpr NeighborResult findNeighbor(const uint8_t map[256][256], loction l, direction dir) {
        uint16_t n = 0;
        loction ln = l;
        for (;;) {
            ln = move(ln, dir);
            uint8_t m = map[ln.y][ln.x];
            if (isCross(m)) {
                break;
            }
            if (ln == l) {
                break;
            }
            dir = nextDirection(m, dir);
            n++;
        }
        return {ln, dir, n};
    }
    static constexpr std::optional<NeighborResult> moveToNeighbor(const uint8_t map[256][256], loction l, direction dir, uint16_t n) {
        for (uint16_t i = 0; ; ++i) {
            l = move(l, dir);
            uint8_t m = map[l.y][l.x];
            if (isCross(m)) {
                return std::nullopt;
            }
            if (i >= n) {
                return NeighborResult {l, dir, n};
            }
            dir = nextDirection(m, dir);
        }
    }

    static constexpr bool isRealNeighbor(loction a, loction b) {
        if (a.x == b.x) {
            return abs(a.y - b.y) == 1;
        }
        if (a.y == b.y) {
            return abs(a.x - b.x) == 1;
        }
        return false;
    }

    static constexpr direction getDirection(loction start, loction end) {
        assert(start != end);
        assert((start.x == end.x) || (start.y == end.y));
        if (start.y == end.y) {
            return start.x < end.x
                ? direction::r
                : direction::l
                ;
        }
        return start.y < end.y
            ? direction::b
            : direction::t
            ;
    }

    void world::loadMap(const std::map<loction, uint8_t>& mapData) {
        memset(map, 0, sizeof(map));
        straightVec.clear();
        crossMap.clear();
        crossMapR.clear();

        uint16_t genCrossId = 0;
        uint16_t genStraightId = 0;
        uint32_t genLorryOffset = 0;
        uint16_t crossCount = 0;

        for (auto& [l, bitmask] : mapData) {
            map[l.y][l.x] = bitmask;

            if (isCross(map[l.y][l.x])) {
                roadid  id  { true, genCrossId++ };
                loction loc {(uint8_t)l.x, (uint8_t)l.y};
                crossMap.emplace(loc, id);
                crossMapR.emplace(id, loc);
                ++crossCount;
            }
        }

        if (crossCount <= 0) {
            crossMap.clear();
            crossMapR.clear();
            return;
        }

        crossAry.reset(genCrossId);
        for (auto const& [loc, id]: crossMap) {
            road::crossroad& crossroad = crossAry[id.id];
            uint8_t m = map[loc.y][loc.x];

            for (uint8_t i = 0; i < 4; ++i) {
                direction dir = (direction)i;
                if (m & (1 << i) && !crossroad.hasNeighbor(dir)) {
                    auto result = findNeighbor(map, loc, dir);
                    roadid neighbor_id = crossMap[result.l];
                    road::crossroad& neighbor = crossAry[neighbor_id.id];
                    if (isRealNeighbor(loc, result.l)) {
                        crossroad.setNeighbor(dir, neighbor_id);
                        neighbor.setNeighbor(reverse(result.dir), id);
                    }
                    else if (loc == result.l) {
                        straightData& straight = straightVec.emplace_back(
                            genStraightId++,
                            result.n,
                            loc,
                            dir,
                            dir,
                            id
                        );
                        crossroad.setNeighbor(dir, {false, straight.id});
                    }
                    else {
                        straightData& straight1 = straightVec.emplace_back(
                            genStraightId++,
                            result.n,
                            loc,
                            dir,
                            reverse(result.dir),
                            neighbor_id
                        );
                        crossroad.setNeighbor(dir, {false, straight1.id});

                        straightData& straight2 = straightVec.emplace_back(
                            genStraightId++,
                            result.n,
                            result.l,
                            reverse(result.dir),
                            dir,
                            id
                        );
                        neighbor.setNeighbor(reverse(result.dir), {false, straight2.id});
                    }
                }
            }
        }

        straightAry.reset(genStraightId);
        for (auto& data: straightVec) {
            road::straight& straight = straightAry[data.id];
            straight.init(data.id, data.len * road::straight::N, data.finish_dir);
            straight.setLorryOffset(genLorryOffset);
            straight.setNeighbor(data.neighbor);
            genLorryOffset += data.len * road::straight::N;
        }
        endpointAry.reset(genLorryOffset);
        lorryAry.reset(genLorryOffset);
    }

    lorryid world::createLorry() {
        lorryid lorryId((uint16_t)lorryVec.size());
        roadnet::lorry lorry;
        lorryVec.push_back(lorry);
        return lorryId;
    }
    void world::placeLorry(endpointid e, lorryid l) {
        auto& ep = Endpoint(e);
        ep.popMap.push_back(l);
    }
    void world::update(uint64_t ti) {
        ary_call(*this, ti, lorryVec, &lorry::update);
        ary_call(*this, ti, crossAry, &road::crossroad::update);
        ary_call(*this, ti, straightAry, &road::straight::update);
    }
    basic_road& world::Road(roadid id) {
        assert(id != roadid::invalid());
        if (id.cross) {
            return crossAry[id.id];
        }
        return straightAry[id.id];
    }
    lorryid& world::LorryInRoad(uint32_t index) {
        return lorryAry[index];
    }
    lorry& world::Lorry(lorryid id) {
        assert(id.id < lorryVec.size());
        return lorryVec[id.id];
    }
    endpointid& world::EndpointInRoad(uint32_t index) {
        return endpointAry[index];
    }
    endpoint& world::Endpoint(endpointid id) {
        assert(id.id < endpointVec.size());
        return endpointVec[id.id];
    }

    endpointid world::createEndpoint(uint8_t connection_x, uint8_t connection_y, direction connection_dir) {
        loction l = move({connection_x, connection_y}, connection_dir);
        direction dir = (direction)(((uint8_t)connection_dir + 1) % 4); // direction of straight road
        uint8_t z = (straightDirection(map[l.y][l.x], 0x10) == dir) ? 0x00 : 0x10; // entry point of offset is 0
        road_coord rc = coordConvert(map_coord{l.x, l.y, z});

        // cannot find endpoint, such as endpoint is not connected to any road
        if (rc == road_coord::invalid()) {
            return endpointid(0xffff);
        }

        endpointid endpointId((uint16_t)endpointVec.size());
        roadnet::endpoint endpoint({connection_x, connection_y});
        endpointVec.push_back(endpoint);

        assert(rc.id.cross == 0 && rc.id.id < straightAry.size());
        auto& straight = straightAry[rc.id.id];
        straight.setEndpoint(*this, rc.offset, endpointId);

        EndpointToRoadcoordMap.emplace(endpointId, rc);
        return endpointId;
    }
    bool world::pushLorry(lorryid lorryId, endpointid starting, endpointid ending) {
        if (lorryVec.size() >= (size_t)(uint16_t)-1) {
            return false;
        }

        // TODO remove this
        auto it1 = EndpointToRoadcoordMap.find(starting);
        assert(it1 != EndpointToRoadcoordMap.end());
        auto es = it1->second;
        auto roadIdS = es.id;

        auto it2 = EndpointToRoadcoordMap.find(ending);
        assert(it2 != EndpointToRoadcoordMap.end());
        auto ee = it2->second;
        auto roadIdE = ee.id;
        auto eo = ee.offset;

        auto& lorry = Lorry(lorryId);
        if (!bfs(*this, roadIdS, roadIdE, lorry.path)) {
            return false;
        }
        lorry.pathIdx = 0;
        lorry.ending = {roadIdE.id, eo};
        Endpoint(starting).pushMap.push_back(lorryId);
        return true;
    }

    lorryid world::popLorry(endpointid ending) {
        // the building does not connect to any road
        if (ending.id == 0xffff)
            return lorryid::invalid();
        auto& ep = Endpoint(ending);
        if (ep.popMap.empty()) {
            return lorryid::invalid();
        }

        lorryid lorryId = ep.popMap.front();
        ep.popMap.pop_front();
        return lorryId;
    }

    roadid world::findCrossRoad(loction l) {
        auto iter = crossMap.find(l);
        if (iter != crossMap.end()) {
            return iter->second;
        }
        return roadid::invalid();
    }

    std::optional<loction> world::whereCrossRoad(roadid id) {
        auto iter = crossMapR.find(id);
        if (iter != crossMapR.end()) {
            return iter->second;
        }
        return std::nullopt;
    }

    road_coord world::coordConvert(map_coord mc) {
        if (auto cross = findCrossRoad(mc); cross) {
            if (!isValidRoadType(map[mc.y][mc.x], RoadType(mc.z))) {
                return road_coord::invalid();
            }
            return {cross, mc.z};
        }

        direction dir = straightDirection(map[mc.y][mc.x], mc.z);
        if (dir == direction::n) {
            return road_coord::invalid();
        }
        auto result = findNeighbor(map, mc, dir);
        if (auto cross = findCrossRoad(result.l); cross) {
            roadid id = crossAry[cross.id].neighbor[(uint8_t)reverse(result.dir)];
            assert(id);
            uint16_t n = road::straight::N * result.n + (mc.z & 0x0Fu);
            uint16_t offset = straightAry[id.id].len - n - 1;
            return {id, offset};
        }
        return road_coord::invalid();
    }

    map_coord world::coordConvert(road_coord rc) {
        if (rc.id.cross) {
            if (auto loc = whereCrossRoad(rc.id); loc) {
                return {loc->x, loc->y, (uint8_t)rc.offset};
            }
            return map_coord::invalid();
        }
        if (rc.id.id >= straightVec.size()) {
            return map_coord::invalid();
        }
        auto& straight = straightVec[rc.id.id];
        uint16_t n = road::straight::N * straight.len - rc.offset - 1;
        if (auto res = moveToNeighbor(map, straight.loc, straight.start_dir, n / road::straight::N); res) {
            auto m = map[res->l.y][res->l.x];
            bool b = reverse(res->dir) == straightDirection(m, 0); // TODO: remove this
            uint8_t z = (uint8_t)direction::n;
            if (b)
                z = (uint8_t)straightDirection(m, 0x00);
            else
                z = (uint8_t)straightDirection(m, 0x10);

            return {res->l.x, res->l.y, (uint8_t)((n % road::straight::N) | (z << 4))};
        }
        return map_coord::invalid();
    }
}
